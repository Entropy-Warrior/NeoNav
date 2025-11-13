/// FaviconService.swift
/// Service for fetching website favicons using multiple strategies.
/// Attempts HTML parsing, standard locations, and Google service as fallbacks.

import AppKit
import Foundation

// MARK: - Favicon Service Protocol

protocol FaviconServiceProtocol: AnyObject {
    /// Fetches favicon data for a given URL
    /// - Parameter url: The website URL to fetch favicon for
    /// - Returns: The favicon image data if found
    func fetchFavicon(for url: URL) async throws -> Data?

    /// Refreshes favicons for multiple bookmarks
    /// - Parameter bookmarks: Array of bookmarks to refresh favicons for
    func refreshFavicons(for bookmarks: [Bookmark]) async
}

// MARK: - Favicon Service Errors

enum FaviconError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case noFaviconFound
    case invalidImageData
    case htmlParsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL provided"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case .noFaviconFound:
            "No favicon found for the website"
        case .invalidImageData:
            "Invalid image data received"
        case .htmlParsingFailed:
            "Failed to parse HTML content"
        }
    }
}

// MARK: - Task Manager Actor

/// Manages concurrent favicon fetch tasks with automatic cleanup
actor TaskManager {
    private var activeTasks: Set<Task<Void, Never>> = []
    private var isShuttingDown = false

    func add(_ task: Task<Void, Never>) {
        guard !isShuttingDown else { return }
        activeTasks.insert(task)

        // Automatically remove task when completed
        Task { [weak self] in
            _ = await task.result
            await self?.remove(task)
        }
    }

    func remove(_ task: Task<Void, Never>) {
        activeTasks.remove(task)
    }

    func shutdown() {
        isShuttingDown = true
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}

// MARK: - Favicon Service Implementation

final class FaviconService: FaviconServiceProtocol {
    // MARK: - Properties

    private let urlSession: URLSession
    private let cache: URLCache
    private let taskManager: TaskManager

    // MARK: - Constants

    private enum Constants {
        static let timeoutInterval: TimeInterval = 10
        static let maxConcurrentOperations = 3
        static let cacheSize = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.timeoutInterval
        config.urlCache = URLCache(memoryCapacity: Constants.cacheSize,
                                   diskCapacity: Constants.cacheSize,
                                   diskPath: "favicon_cache")

        urlSession = URLSession(configuration: config)
        cache = config.urlCache!
        taskManager = TaskManager()

        // Register for app termination to clean up resources
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleCleanupSync()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        // Ensure cleanup happens on main thread
        if Thread.isMainThread {
            handleCleanupSync()
        } else {
            DispatchQueue.main.sync {
                handleCleanupSync()
            }
        }
    }

    private func handleCleanupSync() {
        // Clean up URL session
        urlSession.invalidateAndCancel()

        // Use dispatch group to ensure synchronous completion
        let group = DispatchGroup()
        group.enter()

        Task { [taskManager] in
            await taskManager.shutdown()
            group.leave()
        }

        // Wait with timeout to prevent deadlock
        _ = group.wait(timeout: .now() + 2.0)
    }

    // MARK: - Public Methods

    func fetchFavicon(for url: URL) async throws -> Data? {
        // Try each method in sequence until we find a favicon
        if let data = try? await fetchFromHTML(url) {
            return data
        }

        if let data = try? await fetchFromStandardLocation(url) {
            return data
        }

        if let data = try? await fetchFromGoogleService(url) {
            return data
        }

        throw FaviconError.noFaviconFound
    }

    func refreshFavicons(for bookmarks: [Bookmark]) async {
        // Limit concurrent operations to avoid overwhelming the network
        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            var count = 0

            for bookmark in bookmarks {
                if count >= Constants.maxConcurrentOperations {
                    await group.next()
                    count -= 1
                }

                let task = Task { [weak self] in
                    guard let self else { return }
                    if let url = URL(string: bookmark.url) {
                        if let data = try? await fetchFavicon(for: url) {
                            await MainActor.run {
                                NotificationCenter.default.post(
                                    name: .faviconDidUpdate,
                                    object: nil,
                                    userInfo: ["bookmarkID": bookmark.id, "iconData": data]
                                )
                            }
                        }
                    }
                }

                await taskManager.add(task)
                count += 1
            }

            // Wait for remaining tasks
            for await _ in group {}
        }
    }

    // MARK: - Private Methods

    private func fetchFromHTML(_ url: URL) async throws -> Data? {
        // Ensure we have a valid URL with scheme
        let validURL = url.scheme == nil ? URL(string: "https://\(url.absoluteString)") ?? url : url

        var request = URLRequest(url: validURL)
        request.timeoutInterval = 10
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("text/html,application/xhtml+xml,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let html = String(data: data, encoding: .utf8) else {
                throw FaviconError.htmlParsingFailed
            }

            // Try to find favicon in HTML
            if let faviconURL = extractFaviconLink(from: html, baseURL: response.url ?? validURL) {
                return try? await fetchImageData(from: faviconURL)
            }

            return nil
        } catch let error as URLError {
            if error.code == .unsupportedURL {
                // Try with www prefix if original URL failed
                if !validURL.host!.hasPrefix("www."),
                   let wwwURL = URL(string: validURL.absoluteString.replacingOccurrences(of: "://", with: "://www."))
                {
                    return try await fetchFromHTML(wwwURL)
                }
            }
            throw error
        }
    }

    private func fetchFromStandardLocation(_ url: URL) async throws -> Data? {
        let validURL = url.scheme == nil ? URL(string: "https://\(url.absoluteString)") ?? url : url
        guard let host = validURL.host?.replacingOccurrences(of: "localhost", with: "") else {
            throw FaviconError.invalidURL
        }

        // Try common favicon locations
        let possibleLocations = [
            "/favicon.ico",
            "/favicon.png",
            "/assets/favicon.ico",
            "/static/favicon.ico",
            "/images/favicon.ico",
        ]

        // Try both with and without www prefix
        let hosts = [
            host.hasPrefix("www.") ? host : "www.\(host)",
            host.hasPrefix("www.") ? String(host.dropFirst(4)) : host,
        ]

        let schemes = ["https", "http"]

        for scheme in schemes {
            for tryHost in hosts {
                for location in possibleLocations {
                    guard let standardURL = URL(string: "\(scheme)://\(tryHost)\(location)") else { continue }
                    if let data = try? await fetchImageData(from: standardURL) {
                        return data
                    }
                }
            }
        }

        return nil
    }

    private func fetchFromGoogleService(_ url: URL) async throws -> Data? {
        let validURL = url.scheme == nil ? URL(string: "https://\(url.absoluteString)") ?? url : url
        guard let host = validURL.host?.replacingOccurrences(of: "localhost", with: "") else {
            throw FaviconError.invalidURL
        }

        // Clean the domain name
        let cleanHost = host.trimmingCharacters(in: .punctuationCharacters)
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")

        // Try both domain formats: with and without www
        let domains = [
            cleanHost.hasPrefix("www.") ? cleanHost : "www.\(cleanHost)",
            cleanHost.hasPrefix("www.") ? String(cleanHost.dropFirst(4)) : cleanHost,
        ]

        for domain in domains {
            let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? domain
            guard let googleURL = URL(string: "https://www.google.com/s2/favicons?domain=\(encodedDomain)&sz=64") else {
                continue
            }

            if let data = try? await fetchImageData(from: googleURL) {
                return data
            }
        }

        return nil
    }

    private func fetchImageData(from url: URL) async throws -> Data {
        // Check cache first
        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)),
           !cachedResponse.data.isEmpty
        {
            return cachedResponse.data
        }

        // Create request with appropriate headers
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")

        // Fetch if not cached
        let (data, response) = try await urlSession.data(for: request)

        // Cache the response
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200,
           !data.isEmpty,
           let mimeType = httpResponse.mimeType,
           mimeType.hasPrefix("image/")
        {
            cache.storeCachedResponse(
                CachedURLResponse(response: response, data: data),
                for: request
            )
            return data
        }

        throw FaviconError.invalidImageData
    }

    private func extractFaviconLink(from html: String, baseURL: URL) -> URL? {
        // Regex patterns to find favicon links in HTML
        let patterns = [
            #"<link[^>]+rel=["'](?:shortcut )?icon["'][^>]+href=["'](?<url>[^"']+)["']"#,
            #"<link[^>]+href=["'](?<url>[^"']+)["'][^>]+rel=["'](?:shortcut )?icon["']"#,
            #"<link[^>]+rel=["']apple-touch-icon["'][^>]+href=["'](?<url>[^"']+)["']"#,
            #"<link[^>]+rel=["']icon["'][^>]+href=["'](?<url>[^"']+)["']"#,
            #"<link[^>]+rel=["']mask-icon["'][^>]+href=["'](?<url>[^"']+)["']"#,
        ]

        for pattern in patterns {
            if let range = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]),
               let match = try? Regex(pattern).firstMatch(in: html[range]),
               let urlString = match["url"]?.substring
            {
                let cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

                // Skip data URLs
                if cleaned.hasPrefix("data:") {
                    return nil
                }

                // Handle absolute URLs
                if cleaned.hasPrefix("http") {
                    return URL(string: cleaned)
                }

                // Handle protocol-relative URLs
                if cleaned.hasPrefix("//") {
                    return URL(string: "https:\(cleaned)")
                }

                // Handle relative URLs
                if let baseURL = URL(string: baseURL.absoluteString) {
                    return URL(string: cleaned, relativeTo: baseURL)?.absoluteURL
                }
            }
        }

        return nil
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let faviconDidUpdate = Notification.Name("faviconDidUpdate")
}
