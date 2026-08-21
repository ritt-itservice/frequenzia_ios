//
//  RadioBrowserHostResolver.swift
//  Frequenzia
//
//  Server-Discovery für die Radio Browser API (siehe API_REFERENCE.md):
//  "all.api.radio-browser.info" per DNS auflösen liefert die IPs aller
//  Mirror-Server; ein reverse PTR-Lookup je IP liefert deren echten
//  Hostnamen (den man als Base-URL braucht, nicht die nackte IP, sonst
//  schlägt TLS/SNI fehl). Bekannte Falle: die A/AAAA-Records können in der
//  Praxis auf nur einen einzigen eindeutigen Host zeigen – Retry-Logik darf
//  dann nicht crashen, sondern muss auf die volle (ggf. einelementige)
//  Liste zurückfallen.
//

import Foundation

actor RadioBrowserHostResolver {
    static let shared = RadioBrowserHostResolver()

    private let discoveryHost = "all.api.radio-browser.info"
    private let fallbackHost = "de1.api.radio-browser.info"

    private var cachedHosts: [String] = []
    private var lastUsedHost: String?

    /// Liefert einen Basis-Host. Bei `excludeLastUsed` (Retry nach Fehlschlag)
    /// wird der zuletzt verwendete Host ausgeschlossen, sofern noch ein
    /// anderer eindeutiger Host übrig bleibt – sonst wird er trotzdem wieder
    /// verwendet, statt mit einer leeren Kandidatenliste zu crashen.
    func resolveHost(excludeLastUsed: Bool = false) async -> String {
        if cachedHosts.isEmpty {
            cachedHosts = await Self.discoverHosts(discoveryHost: discoveryHost, fallbackHost: fallbackHost)
        }

        var candidates = cachedHosts
        if excludeLastUsed, let lastUsedHost, candidates.count > 1 {
            candidates.removeAll { $0 == lastUsedHost }
        }

        let host = candidates.randomElement() ?? fallbackHost
        lastUsedHost = host
        return host
    }

    /// Erzwingt beim nächsten Aufruf eine erneute DNS-Auflösung.
    func invalidateCache() {
        cachedHosts = []
    }

    private static func discoverHosts(discoveryHost: String, fallbackHost: String) async -> [String] {
        await Task.detached(priority: .utility) {
            let addresses = resolveAddresses(for: discoveryHost)
            guard !addresses.isEmpty else { return [fallbackHost] }

            var hostnames = Set<String>()
            for address in addresses {
                if let hostname = reverseLookup(address) {
                    hostnames.insert(hostname)
                }
            }
            return hostnames.isEmpty ? [fallbackHost] : Array(hostnames)
        }.value
    }
}

/// Löst alle A/AAAA-Adressen für einen Hostnamen auf (blockierend, daher
/// nur von einem Hintergrund-Task aus aufrufen).
private func resolveAddresses(for hostname: String) -> [sockaddr_storage] {
    var hints = addrinfo(
        ai_flags: 0,
        ai_family: AF_UNSPEC,
        ai_socktype: SOCK_STREAM,
        ai_protocol: 0,
        ai_addrlen: 0,
        ai_canonname: nil,
        ai_addr: nil,
        ai_next: nil
    )
    var resultPointer: UnsafeMutablePointer<addrinfo>?
    let status = getaddrinfo(hostname, nil, &hints, &resultPointer)
    guard status == 0, let firstResult = resultPointer else { return [] }
    defer { freeaddrinfo(firstResult) }

    var addresses: [sockaddr_storage] = []
    var current: UnsafeMutablePointer<addrinfo>? = firstResult
    while let info = current {
        var storage = sockaddr_storage()
        withUnsafeMutableBytes(of: &storage) { rawBuffer in
            let source = UnsafeRawBufferPointer(start: info.pointee.ai_addr, count: Int(info.pointee.ai_addrlen))
            rawBuffer.copyMemory(from: source)
        }
        addresses.append(storage)
        current = info.pointee.ai_next
    }
    return addresses
}

/// Reverse-PTR-Lookup einer Adresse; liefert nil, wenn keine Hostnamen-
/// Auflösung möglich ist (z. B. keine PTR-Record hinterlegt).
private func reverseLookup(_ address: sockaddr_storage) -> String? {
    var addr = address
    let addrLen = socklen_t(address.ss_len)
    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))

    let status = withUnsafePointer(to: &addr) { pointer -> Int32 in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            getnameinfo(
                sockaddrPointer,
                addrLen,
                &hostBuffer,
                socklen_t(hostBuffer.count),
                nil,
                0,
                NI_NAMEREQD
            )
        }
    }

    guard status == 0 else { return nil }
    return hostBuffer.withUnsafeBufferPointer { buffer -> String in
        let bytes = buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}
