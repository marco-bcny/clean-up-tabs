//
//  PinnedTabsView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct PinnedTabsView: View {
    let tabs: [TabItem]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            ForEach(tabs) { tab in
                PinnedTabCell(tab: tab)
            }
        }
        .padding(.trailing, 6)
    }
}

struct PinnedTabCell: View {
    let tab: TabItem
    @State private var isHovered = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.5) : Color.black.opacity(0.05))

            FaviconView(favicon: tab.favicon, size: 16)
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    PinnedTabsView(tabs: TabItem.samplePinnedTabs)
        .frame(width: 249)
        .padding()
}
