//
//  ArchivedTabRowView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct ArchivedTabRowView: View {
    let tab: TabItem
    let onRestore: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onRestore) {
            HStack(spacing: 6) {
                // Tab favicon
                FaviconView(favicon: tab.favicon, size: 16)

                Text(tab.title)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                // Arrow down on far right, visible on hover
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                    .opacity(isHovered ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        ArchivedTabRowView(
            tab: TabItem(title: "Dieter Rams: 10 Principles of Good Design - YouTube", favicon: .youtube),
            onRestore: {}
        )
        ArchivedTabRowView(
            tab: TabItem(title: "Best Albums of 2025 - Pitchfork", favicon: .pitchfork),
            onRestore: {}
        )
    }
    .frame(width: 249)
    .padding()
    .background(Color.gray.opacity(0.2))
}
