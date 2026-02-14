//
//  ContentView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct ContentView: View {
    @State private var pinnedTabs = TabItem.samplePinnedTabs
    @State private var openTabs = TabItem.sampleOpenTabs
    @State private var selectedTabId: UUID? = TabItem.sampleOpenTabs.first(where: { $0.isSelected })?.id

    var body: some View {
        DiaMainView(
            pinnedTabs: pinnedTabs,
            openTabs: $openTabs,
            selectedTabId: $selectedTabId
        )
    }
}

struct DiaMainView: View {
    let pinnedTabs: [TabItem]
    @Binding var openTabs: [TabItem]
    @Binding var selectedTabId: UUID?
    @State private var cleanupTrigger = 0

    private var selectedTab: TabItem? {
        openTabs.first(where: { $0.id == selectedTabId })
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                pinnedTabs: pinnedTabs,
                openTabs: $openTabs,
                selectedTabId: $selectedTabId,
                cleanupTrigger: cleanupTrigger
            )

            // Web Contents
            WebContentsView(selectedTab: selectedTab)
                .padding(.top, 6)
                .padding(.trailing, 6)
                .padding(.bottom, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    cleanupTrigger += 1
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Window background material - traffic lights will float on this
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
        )
        .onKeyPress(.return) {
            cleanupTrigger += 1
            return .handled
        }
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = blendingMode
        view.state = .active
        view.material = material
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
        .frame(width: 1051, height: 875)
        .padding(50)
        .background(Color(white: 0.3))
}
