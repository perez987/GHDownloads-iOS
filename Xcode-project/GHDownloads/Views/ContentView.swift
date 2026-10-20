import SwiftUI
import UIKit

private let heroDetailChipWidth: CGFloat = 275
private let compactOutputHeight: CGFloat = 420

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel = TotalDownloadsViewModel()
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            TotalDownloadsView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Label(
                                settings.text(.settings),
                                systemImage: "gearshape"
                            )
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(settings.text(.done)) {
                                isShowingSettings = false
                            }
                        }
                    }
            }
            .environmentObject(settings)
        }
    }
}

struct TotalDownloadsView: View {
    private struct Metric: Identifiable {
        let id: String
        let title: String
        let value: String
        let symbol: String
    }

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject var viewModel: TotalDownloadsViewModel
    @State private var showsCopiedMessage = false
    @State private var copiedMessageTask: Task<Void, Never>?

    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.26),
                    Color(red: 0.14, green: 0.24, blue: 0.34),
                    Color(red: 0.20, green: 0.18, blue: 0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isCompact {
                // iPhone: scroll the whole screen and give the log a fixed height.
                ScrollView {
                    VStack(spacing: 16) {
                        heroCard
                        metricsRow
                        controlsRow
                        outputCard
                            .frame(height: compactOutputHeight)
                    }
                    .padding(16)
                }
            } else {
                // iPad: the log fills the remaining height.
                VStack(spacing: 18) {
                    heroCard
                    metricsRow
                    controlsRow
                    outputCard
                }
                .padding(24)
            }
        }
        .onDisappear {
            copiedMessageTask?.cancel()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        settings.text(.totalDownloadsAppTitle),
                        systemImage: "chart.bar.fill"
                    )
                    .font(
                        .system(
                            size: isCompact ? 22 : 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    Text(settings.text(.totalDownloadsAppSubtitle))
                        .font(isCompact ? .footnote : .body)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                stateBadge
            }

            HStack(spacing: 12) {
                detailChip(
                    title: settings.text(.githubUser),
                    value: settings.trimmedUsername().isEmpty
                        ? settings.text(.notSet) : settings.trimmedUsername()
                )
                .frame(maxWidth: heroDetailChipWidth, alignment: .leading)
                detailChip(
                    title: settings.text(.tokenLabel),
                    value: settings.hasStoredToken
                        ? settings.text(.tokenStored)
                        : settings.text(.tokenOptional)
                )
                .frame(maxWidth: heroDetailChipWidth, alignment: .leading)
                Spacer(minLength: 0)
            }
        }
        .padding(isCompact ? 18 : 24)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var metricsRow: some View {
        HStack(spacing: isCompact ? 10 : 16) {
            ForEach(totalDownloadMetrics) { metric in
                summaryCard(
                    title: metric.title,
                    value: metric.value,
                    symbol: metric.symbol
                )
            }
        }
    }

    private var controlsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                controlButtons(iconOnlySecondaryButtons: false)
                controlButtons(iconOnlySecondaryButtons: true)
            }

            if showsCopiedMessage {
                Label(
                    settings.text(.copiedMessage),
                    systemImage: "checkmark.circle.fill"
                )
                .font(.footnote.weight(.medium))
                .foregroundStyle(.green)
            } else if settings.trimmedUsername().isEmpty {
                Text(settings.text(.reportSettingsHint))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if settings.hasStoredToken == false {
                Text(settings.text(.reportPublicOnlyHint))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func controlButtons(iconOnlySecondaryButtons: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.run(
                    username: settings.trimmedUsername(),
                    token: settings.loadToken(),
                    language: settings.language
                )
            } label: {
                buttonLabel(
                    settings.text(viewModel.isRunning ? .running : .runReport),
                    systemImage: viewModel.isRunning
                        ? "hourglass" : "play.fill",
                    iconOnly: isPhone
                )
                .frame(minWidth: isPhone ? nil : 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isRunning || settings.trimmedUsername().isEmpty)

            Button {
                viewModel.cancel()
            } label: {
                buttonLabel(
                    settings.text(.cancel),
                    systemImage: "stop.fill",
                    iconOnly: iconOnlySecondaryButtons
                )
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isRunning == false)

            Button {
                viewModel.copyOutput()
                showCopiedMessage()
            } label: {
                buttonLabel(
                    settings.text(.copy),
                    systemImage: "doc.on.doc",
                    iconOnly: iconOnlySecondaryButtons
                )
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.outputLines.isEmpty)

            Button {
                viewModel.clearOutput()
            } label: {
                buttonLabel(
                    settings.text(.clear),
                    systemImage: "trash",
                    iconOnly: iconOnlySecondaryButtons
                )
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.outputLines.isEmpty)
        }
        .controlSize(.large)
    }

    @ViewBuilder
    private func buttonLabel(
        _ title: String,
        systemImage: String,
        iconOnly: Bool
    ) -> some View {
        if iconOnly {
            Image(systemName: systemImage)
                .accessibilityLabel(title)
        } else {
            Label(title, systemImage: systemImage)
        }
    }

    private func showCopiedMessage() {
        copiedMessageTask?.cancel()
        showsCopiedMessage = true
        copiedMessageTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard Task.isCancelled == false else {
                return
            }
            showsCopiedMessage = false
        }
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.text(.liveOutput))
                .font(.title3.weight(.semibold))

            OutputLogView(
                lines: viewModel.outputLines,
                emptyStateText: settings.text(.reportOutputEmpty)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.black.opacity(0.22),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .padding(isCompact ? 16 : 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var stateBadge: some View {
        Text(viewModel.runState.title(in: settings.language))
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(badgeBackground, in: Capsule())
    }

    private var badgeBackground: some ShapeStyle {
        switch viewModel.runState {
        case .idle:
            Color.white.opacity(0.12)
        case .running:
            Color.blue.opacity(0.30)
        case .succeeded:
            Color.green.opacity(0.30)
        case .failed:
            Color.red.opacity(0.30)
        case .cancelled:
            Color.orange.opacity(0.30)
        }
    }

    private func summaryCard(title: String, value: String, symbol: String)
        -> some View
    {
        VStack(alignment: .leading, spacing: 8) {
            if isCompact {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
            } else {
                Label(title, systemImage: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(
                    .system(
                        size: isCompact ? 22 : 28,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? 12 : 18)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func detailChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased(with: settings.language.locale))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func summaryValue(_ transform: (DownloadsReportSummary) -> String)
        -> String
    {
        guard let summary = viewModel.lastSummary else {
            return "—"
        }
        return transform(summary)
    }

    private var totalDownloadMetrics: [Metric] {
        [
            Metric(
                id: "repositories",
                title: settings.text(.repositories),
                value: summaryValue { String($0.repositoryCount) },
                symbol: "shippingbox.fill"
            ),
            Metric(
                id: "with-downloads",
                title: settings.text(.withDownloads),
                value: summaryValue { String($0.repositoriesWithDownloads) },
                symbol: "checkmark.seal.fill"
            ),
            Metric(
                id: "total-downloads",
                title: settings.text(.totalDownloads),
                value: summaryValue { String($0.totalDownloads) },
                symbol: "chart.bar.fill"
            ),
        ]
    }
}
