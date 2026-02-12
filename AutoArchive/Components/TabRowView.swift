//
//  TabRowView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct TabRowView: View {
    let tab: TabItem
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            FaviconView(favicon: tab.favicon, size: 16)

            Text(tab.title)
                .font(.system(size: 12))
                .foregroundStyle(tab.favicon.isNewTabPlus ? Color.secondary : Color.primary.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 0.5)
            } else if isHovered {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.5))
            }
        }
        .onTapGesture {
            onSelect?()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

extension TabItem.FaviconType {
    var isNewTabPlus: Bool {
        if case .systemSymbol(let name) = self, name == "plus" {
            return true
        }
        return false
    }
}

#Preview {
    VStack(spacing: 4) {
        TabRowView(tab: TabItem(title: "MIT Introduction to Quantum Physics", favicon: .youtube))
        TabRowView(tab: TabItem(title: "Wikipedia, the free encyclopedia", favicon: .wikipedia))
        TabRowView(tab: TabItem(title: "New Tab", favicon: .dia, isSelected: true))
        TabRowView(tab: TabItem(title: "New Tab", favicon: .systemSymbol("plus")))
    }
    .frame(width: 249)
    .padding()
    .background(Color.gray.opacity(0.2))
}
