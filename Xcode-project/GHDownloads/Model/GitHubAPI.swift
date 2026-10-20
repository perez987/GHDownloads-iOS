import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct AuthenticatedGitHubUser: Decodable, Sendable {
    let login: String
}

struct GitHubAccount: Decodable, Sendable {
    enum AccountType: String, Decodable, Sendable {
        case user = "User"
        case organization = "Organization"
    }

    let login: String
    let type: AccountType
}

struct GitHubRepository: Decodable, Sendable {
    struct Owner: Decodable, Sendable {
        let login: String
    }

    let name: String
    let owner: Owner
}

struct GitHubRelease: Decodable, Sendable {
    let assets: [GitHubAsset]
}

struct GitHubAsset: Decodable, Sendable {
    let downloadCount: Int

    private enum CodingKeys: String, CodingKey {
        case downloadCount = "download_count"
    }
}

struct GitHubAPIErrorPayload: Decodable, Sendable {
    let message: String
}

enum GitHubAPIError: LocalizedError {
    enum ServerMessageFallback {
        case unsuccessfulResponse
    }

    case invalidUsername
    case invalidResponse
    case server(statusCode: Int, message: String, fallback: ServerMessageFallback?)

    var errorDescription: String? {
        errorDescription(in: .english)
    }

    func errorDescription(in language: AppLanguage) -> String {
        switch self {
        case .invalidUsername:
            return language.text(.errorInvalidUsername)
        case .invalidResponse:
            return language.text(.errorInvalidResponse)
        case let .server(statusCode, message, fallback):
            let localizedMessage: String
            switch fallback {
            case .unsuccessfulResponse?:
                localizedMessage = language.text(.errorUnsuccessfulResponse)
            case nil:
                localizedMessage = message
            }
            return language.formatted(.errorServer, statusCode, localizedMessage)
        }
    }
}

struct GitHubAPIClient {
    let username: String
    let token: String?

    private let apiBaseURL = URL(string: "https://api.github.com")!
    private let perPage = 100
    private let decoder = JSONDecoder()

    private var trimmedToken: String? {
        let value = token?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else {
            return nil
        }
        return value
    }

    func fetchAuthenticatedUser() async throws -> AuthenticatedGitHubUser {
        try await get(pathComponents: ["user"], queryItems: [])
    }

    func fetchRequestedAccount() async throws -> GitHubAccount {
        try await get(pathComponents: ["users", username], queryItems: [])
    }

    func fetchAuthenticatedRepositories(page: Int) async throws -> [GitHubRepository] {
        try await get(
            pathComponents: ["user", "repos"],
            queryItems: [
                URLQueryItem(name: "affiliation", value: "owner"),
                URLQueryItem(name: "sort", value: "full_name"),
                URLQueryItem(name: "direction", value: "asc"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    func fetchPublicUserRepositories(page: Int) async throws -> [GitHubRepository] {
        try await get(
            pathComponents: ["users", username, "repos"],
            queryItems: [
                URLQueryItem(name: "type", value: "owner"),
                URLQueryItem(name: "sort", value: "full_name"),
                URLQueryItem(name: "direction", value: "asc"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    func fetchOrganizationRepositories(page: Int) async throws -> [GitHubRepository] {
        try await get(
            pathComponents: ["orgs", username, "repos"],
            queryItems: [
                URLQueryItem(name: "type", value: "all"),
                URLQueryItem(name: "sort", value: "full_name"),
                URLQueryItem(name: "direction", value: "asc"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    func fetchReleases(ownerName: String, repositoryName: String, page: Int) async throws -> [GitHubRelease] {
        try await get(
            pathComponents: ["repos", ownerName, repositoryName, "releases"],
            queryItems: [
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    private func get<T: Decodable>(pathComponents: [String], queryItems: [URLQueryItem]) async throws -> T {
        let request = try makeRequest(pathComponents: pathComponents, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func makeRequest(pathComponents: [String], queryItems: [URLQueryItem]) throws -> URLRequest {
        var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)
        components?.percentEncodedPath = "/" + pathComponents.map(encodedPathComponent).joined(separator: "/")
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw GitHubAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("GHDownloadsApp", forHTTPHeaderField: "User-Agent")
        if let trimmedToken {
            request.setValue("Bearer " + trimmedToken, forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func encodedPathComponent(_ component: String) -> String {
        let allowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        return component.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? component
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let payload = try? decoder.decode(GitHubAPIErrorPayload.self, from: data)
            throw GitHubAPIError.server(
                statusCode: httpResponse.statusCode,
                message: payload?.message ?? AppLanguage.english.text(.errorUnsuccessfulResponse),
                fallback: payload == nil ? .unsuccessfulResponse : nil
            )
        }
    }
}
