import SwiftUI
import UIKit

struct OutputLogView: View {
    private struct ScrollTrigger: Equatable {
        let lineCount: Int
        let lastLine: String?
        let viewportSize: CGSize
    }

    let lines: [String]
    let emptyStateText: String
    private let bottomAnchorID = "output-log-bottom-anchor"

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { viewport in
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 6) {
                        if lines.isEmpty {
                            Text(emptyStateText)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(width: max(viewport.size.width - 36, 0), alignment: .leading)
                                .padding(.top, 4)
                        } else {
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                Text(verbatim: line)
//                                    .font(.system(.footnote, design: .monospaced))
                                    .font(.system(UIDevice.current.userInterfaceIdiom == .phone ? .caption2 : .body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .id("line-\(index)")
                            }
                        }
                        Color.clear
                            .frame(width: 1, height: 1)
                            .padding(.bottom, 18)
                            .id(bottomAnchorID)
                    }
                    .textSelection(.enabled)
                    .padding([.top, .horizontal], 18)
                    .frame(minWidth: viewport.size.width, alignment: .leading)
                }
                .defaultScrollAnchor(.bottomLeading)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .task(id: ScrollTrigger(
                    lineCount: lines.count,
                    lastLine: lines.last,
                    viewportSize: viewport.size
                )) {
                    // New output or completed layout cancels any stale scroll request.
                    await Task.yield()
                    guard !Task.isCancelled else {
                        return
                    }
                    proxy.scrollTo(bottomAnchorID, anchor: .bottomLeading)
                }
            }
        }
    }
}
