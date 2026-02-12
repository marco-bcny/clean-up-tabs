//
//  SidebarView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct SidebarView: View {
    let pinnedTabs: [TabItem]
    @Binding var openTabs: [TabItem]
    @Binding var selectedTabId: UUID?
    var demoArchivedCount: Int = 0
    var onDemoAreaTapped: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Actions
            TopActionsBar()

            // Pinned Tabs
            PinnedTabsView(tabs: pinnedTabs)
                .padding(.leading, 6)
                .padding(.top, 6)

            // Open Tabs - takes remaining space
            OpenTabsSection(
                tabs: $openTabs,
                selectedTabId: $selectedTabId,
                demoArchivedCount: demoArchivedCount,
                onDemoAreaTapped: onDemoAreaTapped
            )
            .padding(.leading, 6)
        }
        .frame(width: 249)
    }
}

struct TopActionsBar: View {
    // Space for custom traffic lights (added via AppDelegate)
    private let trafficLightWidth: CGFloat = 72

    var body: some View {
        HStack(spacing: 10) {
            // Space for traffic lights (positioned by AppDelegate)
            Spacer()
                .frame(width: trafficLightWidth)

            // Profile Switcher
            Text("Personal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            // Sidebar toggle
            Text("􀆈")
                .font(.system(size: 12.565, weight: .regular, design: .rounded))
                .foregroundStyle(.primary.opacity(0.85))
                .frame(width: 24, height: 24)
                .padding(.trailing, 6)
        }
        .frame(height: 14)
        .padding(.top, 17)
    }
}

struct OpenTabsSection: View {
    @Binding var tabs: [TabItem]
    @Binding var selectedTabId: UUID?
    var demoArchivedCount: Int = 0
    var onDemoAreaTapped: (() -> Void)? = nil

    @State private var showArchivedTabs = false
    @State private var scrollOffset: CGFloat = 0
    @State private var displayedArchivedTabs: [TabItem] = TabItem.sampleArchivedTabs
    @State private var restoredTabs: [TabItem] = []
    @State private var pulledPastThreshold = false
    @State private var isRevealing = false
    @State private var revealCompensation: CGFloat = 0
    @Namespace private var tabAnimation

    private let revealThreshold: CGFloat = -12

    private func selectTab(_ tab: TabItem) {
        selectedTabId = tab.id

        // Auto-hide archived tabs when selecting an open tab
        if showArchivedTabs {
            hideArchivedTabs()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Pull hint tab
            if !showArchivedTabs {
                PullHintTabView(
                    scrollOffset: scrollOffset,
                    revealThreshold: revealThreshold,
                    badgeCount: demoArchivedCount,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showArchivedTabs = true
                        }
                    }
                )
                .padding(.trailing, 6)
                .offset(y: scrollOffset < 0 ? -scrollOffset : 0)
            }

            // Scrollable Tab List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Archived Tabs Section
                    if showArchivedTabs {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Archived Tabs")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 2)

                            ForEach(displayedArchivedTabs) { tab in
                                ArchivedTabRowView(tab: tab) {
                                    restoreTab(tab)
                                }
                                .matchedGeometryEffect(id: tab.id, in: tabAnimation)
                            }

                            // Hide Archived Tabs button at the end
                            HideArchivedTabsView {
                                hideArchivedTabs()
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Recent Tabs Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Tabs")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.top, 8)
                            .opacity(showArchivedTabs ? 1 : 0)
                            .frame(height: showArchivedTabs ? nil : 0, alignment: .top)
                            .clipped()

                        // All tabs except the last one (New Tab button)
                        ForEach(tabs.dropLast()) { tab in
                            TabRowView(tab: tab, isSelected: tab.id == selectedTabId) {
                                selectTab(tab)
                            }
                        }

                        // Restored tabs animate here from archived section (before New Tab)
                        ForEach(restoredTabs) { tab in
                            TabRowView(tab: tab, isSelected: tab.id == selectedTabId) {
                                selectTab(tab)
                            }
                            .matchedGeometryEffect(id: tab.id, in: tabAnimation)
                        }

                        // New Tab button always last
                        if let lastTab = tabs.last {
                            TabRowView(tab: lastTab, isSelected: lastTab.id == selectedTabId) {
                                selectTab(lastTab)
                            }
                        }
                    }
                    // Compensate for rubberband during reveal - holds position steady
                    .offset(y: revealCompensation)
                }
                .padding(.trailing, 6)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { oldValue, newValue in
                // During reveal, compensate for rubberband bounce-back
                if isRevealing {
                    // As scroll bounces back toward 0, increase compensation to hold position
                    let bounceback = newValue - oldValue
                    if newValue < 0 && bounceback > 0 {
                        revealCompensation -= bounceback
                    }
                } else {
                    scrollOffset = newValue
                    if newValue < revealThreshold {
                        pulledPastThreshold = true
                    }
                }
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                // Reveal immediately when finger lifts
                if oldPhase == .interacting && pulledPastThreshold && !showArchivedTabs {
                    isRevealing = true
                    revealCompensation = 0

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showArchivedTabs = true
                    }
                    pulledPastThreshold = false
                }
                // When scroll settles, clear compensation
                if newPhase == .idle {
                    if isRevealing {
                        withAnimation(.easeOut(duration: 0.15)) {
                            revealCompensation = 0
                        }
                        isRevealing = false
                    }
                    pulledPastThreshold = false
                }
            }
            .scrollBounceBehavior(.always)
        }
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            // Hidden click area for demo
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .contentShape(Rectangle())
                .onTapGesture {
                    onDemoAreaTapped?()
                }
        }
    }

    private func restoreTab(_ tab: TabItem) {
        // Animate the tab from archived to open tabs using matched geometry
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            displayedArchivedTabs.removeAll { $0.id == tab.id }
            restoredTabs.append(tab)
        }

        // Hide archived section if no more archived tabs
        if displayedArchivedTabs.isEmpty {
            hideArchivedTabs()
        }
    }

    private func hideArchivedTabs() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showArchivedTabs = false
        }
        // Don't reset archived tabs - restored tabs should stay restored
    }
}

// MARK: - Pull Hint Tab View

struct PullHintTabView: View {
    let scrollOffset: CGFloat
    let revealThreshold: CGFloat
    var badgeCount: Int = 0
    let onTap: () -> Void

    @State private var isHovered = false

    private var isPastThreshold: Bool {
        scrollOffset < revealThreshold
    }

    private var title: String {
        isPastThreshold ? "Release to See Archived Tabs" : "Recently Archived"
    }

    private var showArrow: Bool {
        isHovered || isPastThreshold
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Image(systemName: "archivebox")
                    .font(.system(size: 12, weight: .medium))
                    .imageScale(.large)
                    .opacity(showArrow ? 0 : 1)
                    .offset(y: showArrow ? 10 : 0)

                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .imageScale(.large)
                    .opacity(showArrow ? 1 : 0)
                    .offset(y: showArrow ? 0 : -10)
            }
            .frame(width: 16, height: 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showArrow)

            Text(title)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Badge for archived count
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(.tertiary)
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
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Hide Archived Tabs View

struct HideArchivedTabsView: View {
    let onHide: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 16, height: 16)

            Text("Hide Archived Tabs")
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(.tertiary)
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
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onHide()
        }
    }
}

#Preview {
    @Previewable @State var openTabs = TabItem.sampleOpenTabs
    @Previewable @State var selectedTabId: UUID? = TabItem.sampleOpenTabs.first(where: { $0.isSelected })?.id

    SidebarView(
        pinnedTabs: TabItem.samplePinnedTabs,
        openTabs: $openTabs,
        selectedTabId: $selectedTabId
    )
    .background(Color.gray.opacity(0.16))
}
