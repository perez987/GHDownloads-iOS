import Foundation

struct DownloadsReportSummary {
    let repositoryCount: Int
    let repositoriesWithDownloads: Int
    let totalDownloads: Int
}

struct DownloadsTableFormatter {
    private static let minimumNameWidth = 45
    private static let minimumCountWidth = 15

    let language: AppLanguage

    private var nameWidth: Int {
        max(Self.minimumNameWidth, language.text(.downloadsTableRepositoryHeader).count)
    }

    private var countWidth: Int {
        max(Self.minimumCountWidth, language.text(.downloadsTableDownloadsHeader).count)
    }

    func header() -> [String] {
        [
            row(name: language.text(.downloadsTableRepositoryHeader), count: language.text(.downloadsTableDownloadsHeader)),
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
        ]
    }

    func repositoryRow(name: String, downloads: Int) -> String {
        row(name: name, count: String(downloads))
    }

    func footer(totalDownloads: Int) -> [String] {
        [
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
            row(name: language.text(.totalDownloads).uppercased(with: language.locale), count: String(totalDownloads)),
        ]
    }

    private func row(name: String, count: String) -> String {
        let left = truncate(name, to: nameWidth).padding(toLength: nameWidth, withPad: " ", startingAt: 0)
        let right = count.leftPadded(to: countWidth)
        return "\(left) \(right)"
    }

    private func truncate(_ value: String, to width: Int) -> String {
        guard value.count > width else {
            return value
        }

        let suffix = "…"
        let prefixCount = max(width - suffix.count, 0)
        return String(value.prefix(prefixCount)) + suffix
    }
}

struct DownloadsReportRunner {
    private static let maxConcurrentRepositoryRequests = 6

    let username: String
    let token: String?
    let language: AppLanguage

    func run(emit: @escaping @Sendable (String) async -> Void) async throws -> DownloadsReportSummary {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUsername.isEmpty == false else {
            throw GitHubAPIError.invalidUsername
        }

        let client = GitHubAPIClient(username: trimmedUsername, token: token)
        let formatter = DownloadsTableFormatter(language: language)
        let fetchRepositories = try await repositoryPageFetcher(client: client, username: trimmedUsername)

        await emit(language.formatted(.logUser, trimmedUsername))
        await emit(language.text(.logQueryingReleaseDownloads))
        await emit("")
        for line in formatter.header() {
            await emit(line)
        }

        var allRepositories: [GitHubRepository] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let repositories = try await fetchRepositories(page)
            guard repositories.isEmpty == false else {
                break
            }

            allRepositories.append(contentsOf: repositories)
            if repositories.count < 100 {
                break
            }
            page += 1
        }

        if allRepositories.isEmpty {
            await emit(language.text(.logNoRepositoriesFound))
        } else {
            let downloadsByRepository = try await fetchDownloadsByRepository(
                repositories: allRepositories,
                username: trimmedUsername,
                token: token
            )

            var grandTotal = 0
            var repositoriesWithDownloads = 0

            for (repository, downloads) in zip(allRepositories, downloadsByRepository) {
                await emit(formatter.repositoryRow(name: repository.name, downloads: downloads))
                grandTotal += downloads
                if downloads > 0 {
                    repositoriesWithDownloads += 1
                }
            }

            for line in formatter.footer(totalDownloads: grandTotal) {
                await emit(line)
            }
            await emit("")
            await emit(language.formatted(.logRepositoriesAnalyzed, allRepositories.count))
            await emit(language.formatted(.logRepositoriesWithDownloads, repositoriesWithDownloads))

            return DownloadsReportSummary(
                repositoryCount: allRepositories.count,
                repositoriesWithDownloads: repositoriesWithDownloads,
                totalDownloads: grandTotal
            )
        }

        for line in formatter.footer(totalDownloads: 0) {
            await emit(line)
        }
        await emit("")
        await emit(language.formatted(.logRepositoriesAnalyzed, 0))
        await emit(language.formatted(.logRepositoriesWithDownloads, 0))
        return DownloadsReportSummary(
            repositoryCount: 0,
            repositoriesWithDownloads: 0,
            totalDownloads: 0
        )
    }

    private func repositoryPageFetcher(
        client: GitHubAPIClient,
        username: String
    ) async throws -> (Int) async throws -> [GitHubRepository] {
        if token?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
           let authenticatedUser = try? await client.fetchAuthenticatedUser(),
           authenticatedUser.login.caseInsensitiveCompare(username) == .orderedSame
        {
            return { page in
                try await client.fetchAuthenticatedRepositories(page: page)
            }
        }

        let account = try await client.fetchRequestedAccount()
        switch account.type {
        case .user:
            return { page in
                try await client.fetchPublicUserRepositories(page: page)
            }
        case .organization:
            return { page in
                try await client.fetchOrganizationRepositories(page: page)
            }
        }
    }

    private func fetchDownloadsByRepository(
        repositories: [GitHubRepository],
        username: String,
        token: String?
    ) async throws -> [Int] {
        let initialCount = min(Self.maxConcurrentRepositoryRequests, repositories.count)
        var nextIndex = initialCount
        var downloadsByRepository = Array(repeating: 0, count: repositories.count)

        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            for index in 0 ..< initialCount {
                addDownloadsTask(
                    to: &group,
                    index: index,
                    repository: repositories[index],
                    username: username,
                    token: token
                )
            }

            while let (index, downloads) = try await group.next() {
                downloadsByRepository[index] = downloads
                if nextIndex < repositories.count {
                    addDownloadsTask(
                        to: &group,
                        index: nextIndex,
                        repository: repositories[nextIndex],
                        username: username,
                        token: token
                    )
                    nextIndex += 1
                }
            }
        }

        return downloadsByRepository
    }

    private func addDownloadsTask(
        to group: inout ThrowingTaskGroup<(Int, Int), Error>,
        index: Int,
        repository: GitHubRepository,
        username: String,
        token: String?
    ) {
        group.addTask {
            let client = GitHubAPIClient(username: username, token: token)
            let downloads = try await Self.fetchDownloads(for: repository, client: client)
            return (index, downloads)
        }
    }

    private static func fetchDownloads(for repository: GitHubRepository, client: GitHubAPIClient) async throws -> Int {
        var page = 1
        var total = 0

        while true {
            try Task.checkCancellation()
            let releases = try await client.fetchReleases(
                ownerName: repository.owner.login,
                repositoryName: repository.name,
                page: page
            )
            guard releases.isEmpty == false else {
                break
            }

            total += releases
                .flatMap(\.assets)
                .reduce(0) { partialResult, asset in
                    partialResult + asset.downloadCount
                }

            if releases.count < 100 {
                break
            }
            page += 1
        }

        return total
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        guard count < width else {
            return self
        }
        return String(repeating: " ", count: width - count) + self
    }
}
