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

    @State private var showArchiveDemo = false
    @State private var demoArchivedCount = 0

    private var selectedTab: TabItem? {
        openTabs.first(where: { $0.id == selectedTabId })
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Sidebar
                SidebarView(
                    pinnedTabs: pinnedTabs,
                    openTabs: $openTabs,
                    selectedTabId: $selectedTabId,
                    demoArchivedCount: demoArchivedCount,
                    onDemoAreaTapped: {
                        triggerArchiveDemo()
                    }
                )

                // Web Contents
                WebContentsView(selectedTab: selectedTab)
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
            }

            // Archive demo overlay
            if showArchiveDemo {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)

                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                    Text("Unused tabs are archived overnight")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundStyle(.white)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Window background material - traffic lights will float on this
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
        )
    }

    private func triggerArchiveDemo() {
        if demoArchivedCount > 0 {
            // Restore mode - reset archived count
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                demoArchivedCount = 0
            }
        } else {
            // Archive mode - show overlay then archive tabs
            withAnimation(.easeInOut(duration: 0.3)) {
                showArchiveDemo = true
            }

            // After 3 seconds, hide overlay and archive tabs
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showArchiveDemo = false
                }

                // Animate in the archived count
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    demoArchivedCount = 10
                }
            }
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
