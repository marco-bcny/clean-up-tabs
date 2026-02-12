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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.05))

            FaviconView(favicon: tab.favicon, size: 25)
        }
        .frame(height: 40)
    }
}

#Preview {
    PinnedTabsView(tabs: TabItem.samplePinnedTabs)
        .frame(width: 249)
        .padding()
}
