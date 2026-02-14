//
//  TabSearchMenuView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 2/12/26.
//

import SwiftUI

struct TabSearchMenuView: View {
    let openTabs: [TabItem]
    @State private var searchText = ""

    private let recentlyClosedTabs: [TabItem] = [
        TabItem(title: "Wikipedia", favicon: .wikipedia),
        TabItem(title: "Youtube", favicon: .youtube),
        TabItem(title: "Reddit", favicon: .reddit),
    ]

    private var displayOpenTabs: [TabItem] {
        let realTabs = openTabs.filter { tab in
            tab.title != "New Tab" && !tab.favicon.isNewTabPlus
        }
        if searchText.isEmpty {
            return Array(realTabs.prefix(3))
        }
        return realTabs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var displayRecentlyClosedTabs: [TabItem] {
        if searchText.isEmpty {
            return recentlyClosedTabs
        }
        return recentlyClosedTabs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack(spacing: 0) {
                TextField("Search Tabs", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                Spacer(minLength: 4)

                Text("⌘A")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(.primary.opacity(0.06))
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Open Tabs
            if !displayOpenTabs.isEmpty {
                menuSectionHeader("Open Tabs")
                ForEach(displayOpenTabs) { tab in
                    menuTabRow(tab: tab)
                }
            }

            menuSeparator()

            // Recently Closed
            if !displayRecentlyClosedTabs.isEmpty {
                menuSectionHeader("Recently Closed")
                ForEach(displayRecentlyClosedTabs) { tab in
                    menuTabRow(tab: tab)
                }
            }

            menuSeparator()

            // Bottom menu items
            menuNavItem(icon: "book", title: "Bookmarks")
            menuNavItem(icon: "folder", title: "Groups")
            menuNavItem(icon: "clock", title: "History")
            menuNavItem(icon: "bubble.left", title: "Chats")
        }
        .padding(.vertical, 5)
        .frame(width: 318)
    }

    // MARK: - Section Header

    private func menuSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(height: 21, alignment: .bottomLeading)
            .padding(.horizontal, 18)
    }

    // MARK: - Tab Row

    private func menuTabRow(tab: TabItem) -> some View {
        MenuRowButton {
            // action
        } label: {
            HStack(spacing: 6) {
                FaviconView(favicon: tab.favicon, size: 16)
                Text(tab.title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    // MARK: - Nav Item (with chevron)

    private func menuNavItem(icon: String, title: String) -> some View {
        MenuRowButton {
            // action
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .imageScale(.large)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Separator

    private func menuSeparator() -> some View {
        Divider()
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }
}

// MARK: - Reusable hover-able menu row button

private struct MenuRowButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                .frame(height: 24)
                .contentShape(Rectangle())
                .background {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                    }
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    TabSearchMenuView(openTabs: TabItem.sampleOpenTabs)
        .background(.ultraThickMaterial)
}
