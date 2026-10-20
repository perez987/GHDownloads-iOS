# CLAUDE.md

## Project overview

- `GHDownloads` is a native iOS/iPadOS 18+ SwiftUI app (iPhone and iPad) that reports the total release-asset downloads across all repositories owned by a GitHub account.
- It is the iOS port of the macOS [GH Get Repos](https://github.com/perez987/GHGetRepos) app. The repository-download (git clone) feature was intentionally removed and must not be reintroduced.
- The Xcode project is under `Xcode-project/`.
- App source lives in `Xcode-project/GHDownloads/`.
- UI code lives in `Xcode-project/GHDownloads/Views/`.
- State, networking, and run logic live in `Xcode-project/GHDownloads/Model/`.

## Important files

- `Xcode-project/GHDownloads/GHDownloadsApp.swift`: app entry point and shared `SettingsStore` injection (dark color scheme).
- `Xcode-project/GHDownloads/Views/ContentView.swift`: main screen (`NavigationStack` with a settings toolbar button that presents `SettingsView` as a sheet) and `TotalDownloadsView`. Uses a scrolling layout on compact size classes (iPhone) and a full-height layout on regular size classes (iPad).
- `Xcode-project/GHDownloads/Views/SettingsView.swift`: username, token, and language settings UI.
- `Xcode-project/GHDownloads/Views/OutputLogView.swift`: selectable live log output with continuous non-wrapped lines, horizontal and vertical scrolling, and auto-scroll to the bottom.
- `Xcode-project/GHDownloads/Model/AppViewModel.swift`: shared run lifecycle (`BaseRunViewModel`), cancellation handling, copy to `UIPasteboard`, and `TotalDownloadsViewModel`.
- `Xcode-project/GHDownloads/Model/DownloadsReportRunner.swift`: repository listing, per-repository release download counting, table formatting, and result summary.
- `Xcode-project/GHDownloads/Model/GitHubAPI.swift`: GitHub API models, requests, and HTTP helpers.
- `Xcode-project/GHDownloads/Model/SettingsStore.swift`: localized strings (`AppLanguage`, `L10nKey`), persisted username/language, and token-loading bridge.
- `Xcode-project/GHDownloads/Model/KeychainTokenStore.swift`: Keychain-backed token storage (`github-release-downloads` service, `WhenUnlockedThisDeviceOnly` accessibility).

## Working conventions

- Prefer small, focused SwiftUI and model changes.
- Keep token handling in the Keychain-backed store; do not move secrets into `UserDefaults`.
- Preserve cancellation behavior for the downloads report.
- Results are not persisted; they are only shown in the output log, which can be copied or cleared.
- Every user-facing string goes through `L10nKey` with both English and Spanish translations.

## Validation

- Open in Xcode: `Xcode-project/GHDownloads.xcodeproj`
- Validate from repository root:
  - `xcodebuild -project Xcode-project/GHDownloads.xcodeproj -scheme GHDownloads -destination 'generic/platform=iOS Simulator' build`
- There is currently no test target checked into this repository.

## Notes for agents

- This is a SwiftUI iOS/iPadOS app, not a package or command-line tool.
- The app has a single main screen; settings are shown in a sheet.
- Avoid broad UI restyling unless the task specifically asks for it.
