//
//  TabItem.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let favicon: FaviconType
    var isSelected: Bool = false
    var isPinned: Bool = false

    enum FaviconType {
        case systemSymbol(String)
        case remote(URL)
        case dia
        // Asset-based favicons
        case google
        case youtube
        case wikipedia
        case reddit
        case pitchfork
        case verge
        case architecturalDigest
        case designWithinReach
        case polygon
        case nyt
        case onShoes
        case nike
    }
}

extension TabItem {
    static let samplePinnedTabs: [TabItem] = [
        TabItem(title: "Google", favicon: .google, isPinned: true),
        TabItem(title: "YouTube", favicon: .youtube, isPinned: true),
        TabItem(title: "Reddit", favicon: .reddit, isPinned: true),
        TabItem(title: "Wikipedia", favicon: .wikipedia, isPinned: true)
    ]

    static let sampleOpenTabs: [TabItem] = [
        TabItem(title: "Tiny Desk Concert: Billie Eilish - NPR", favicon: .youtube),
        TabItem(title: "best running shoes 2026 - Google Search", favicon: .google),
        TabItem(title: "Bauhaus - Wikipedia", favicon: .wikipedia),
        TabItem(title: "New Tab", favicon: .dia),
        TabItem(title: "New Tab", favicon: .dia),
        TabItem(title: "r/architecture - The brutalist revival in modern cities", favicon: .reddit),
        TabItem(title: "The Rise of Adaptive Reuse in Urban Design - NYT", favicon: .nyt),
        TabItem(title: "Apple Vision Pro 2 Review - The Verge", favicon: .verge),
        TabItem(title: "Bauhaus - Wikipedia", favicon: .wikipedia),
        TabItem(title: "New Tab", favicon: .dia),
        TabItem(title: "Elden Ring DLC: Shadow of the Erdtree Review - Polygon", favicon: .polygon),
        TabItem(title: "Kendrick Lamar's New Album: A Track-by-Track Review - Pitchfork", favicon: .pitchfork),
        TabItem(title: "Eames Lounge Chair and Ottoman - Design Within Reach", favicon: .designWithinReach),
        TabItem(title: "Cloudmonster 2 - On Running", favicon: .onShoes),
        TabItem(title: "New Tab", favicon: .dia),
        TabItem(title: "Pegasus 41 Running Shoes - Nike", favicon: .nike),
        TabItem(title: "Inside Tadao Ando's Concrete Masterpiece - AD", favicon: .architecturalDigest),
        TabItem(title: "Tiny Desk Concert: Billie Eilish - NPR", favicon: .youtube),
        TabItem(title: "New Tab", favicon: .dia, isSelected: true),
        TabItem(title: "New Tab", favicon: .systemSymbol("plus"))
    ]
}
