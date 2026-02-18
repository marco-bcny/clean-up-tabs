//
//  SidebarView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

// MARK: - SidebarView

struct SidebarView: View {
    let pinnedTabs: [TabItem]
    @Binding var openTabs: [TabItem]
    @Binding var selectedTabId: UUID?
    var cleanupTrigger: Int = 0

    // Cleanup animation state
    @State private var cleanupIDs: Set<UUID> = []
    @State private var namesFaded = false
    @State private var rowsCollapsed = false
    @State private var cleanedUpCount = 0
    @State private var hasCleanedUp = false
    @State private var isAnimating = false

    // Saved state for restore
    @State private var savedTabs: [TabItem]? = nil

    // Platter state
    @State private var showPlatter = false
    @State private var expandPlatter = false
    @State private var showGlow = false
    @State private var personalHidden = false
    @State private var platterScale: CGFloat = 1.0
    @State private var platterOpacity: CGFloat = 1.0


    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TopActionsBar(
                showPlatter: showPlatter,
                expandPlatter: expandPlatter,
                cleanedUpCount: cleanedUpCount,
                showGlow: showGlow,
                personalHidden: personalHidden,
                platterScale: platterScale,
                platterOpacity: platterOpacity
            )

            PinnedTabsView(tabs: pinnedTabs)
                .padding(.leading, 6)
                .padding(.top, 6)

            OpenTabsSection(
                tabs: $openTabs,
                selectedTabId: $selectedTabId,
                cleanupIDs: cleanupIDs,
                namesFaded: namesFaded,
                rowsCollapsed: rowsCollapsed
            )
            .padding(.leading, 6)
        }
        .frame(width: 249)
        .onChange(of: cleanupTrigger) {
            handleToggle()
        }
    }

    // MARK: - Chevron tap handler (toggle)

    private func handleToggle() {
        guard !isAnimating else { return }
        if hasCleanedUp {
            restoreTabs()
        } else {
            performCleanup()
        }
    }

    // MARK: - Restore

    private func restoreTabs() {
        guard let saved = savedTabs else { return }

        let dismissDuration = 0.15

        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
            expandPlatter = false
            personalHidden = false
            showGlow = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration) {
            withAnimation(.easeOut(duration: 0.08)) {
                platterOpacity = 0
            }
        }

        let cleanupTime = dismissDuration + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + cleanupTime) {
            showPlatter = false
            platterOpacity = 1.0
            withAnimation(.easeInOut(duration: 0.35)) {
                openTabs = saved
            }
            savedTabs = nil
            hasCleanedUp = false
        }
    }

    // MARK: - Dismiss Platter

    private func dismissPlatter() {
        let dismissDuration = 0.15

        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
            expandPlatter = false
            personalHidden = false
            showGlow = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration) {
            withAnimation(.easeOut(duration: 0.08)) {
                platterOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration + 0.1) {
            showPlatter = false
            platterOpacity = 1.0
        }
    }

    // MARK: - Cleanup

    private func performCleanup() {
        isAnimating = true

        // Save current state for restore
        savedTabs = openTabs

        let allTabs = Array(openTabs.dropLast()) // exclude + button
        var idsToRemove: Set<UUID> = []

        // Inactive new tabs (not selected, not +)
        for tab in allTabs {
            if tab.title == "New Tab" && !tab.isSelected {
                idsToRemove.insert(tab.id)
            }
        }

        // Duplicates by title (keep last occurrence, remove earlier ones)
        var seen: [String: UUID] = [:]
        for tab in allTabs.reversed() where tab.title != "New Tab" {
            if seen[tab.title] != nil {
                idsToRemove.insert(tab.id)
            } else {
                seen[tab.title] = tab.id
            }
        }

        guard !idsToRemove.isEmpty else {
            isAnimating = false
            return
        }

        cleanupIDs = idsToRemove
        cleanedUpCount = idsToRemove.count

        // Phase 1: Fade names
        withAnimation(.easeOut(duration: 0.3)) {
            namesFaded = true
        }

        // Phase 2: Collapse rows (favicons fade out with their rows)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                rowsCollapsed = true
            }
        }

        // Phase 3: Show platter + glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) {
                showPlatter = true
                showGlow = true
            }
            withAnimation(.easeOut(duration: 0.45)) {
                platterScale = 1.28
            }
        }

        // Scale back down with bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + 0.45 + 0.5) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                platterScale = 1.0
            }
        }

        // Phase 4: Expand platter — label + stack appear together
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                expandPlatter = true
                personalHidden = true
            }

            hasCleanedUp = true
            isAnimating = false

            // Phase 5: Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissPlatter()
            }
        }

        // Phase 6: Remove tabs after rows collapse
        let rowsCollapseTime = 0.15 + 0.4 + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + rowsCollapseTime) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                openTabs.removeAll { idsToRemove.contains($0.id) }
            }

            cleanupIDs = []
            namesFaded = false
            rowsCollapsed = false
        }
    }
}

// MARK: - TopActionsBar

// MARK: - Dia Chroma Colors

enum DiaChroma {
    static let maroon = Color(red: 106/255, green: 23/255, blue: 49/255)
    static let darkBlue = Color(red: 51/255, green: 76/255, blue: 180/255)
    static let lightBlue = Color(red: 45/255, green: 129/255, blue: 255/255)
    static let yellow = Color(red: 205/255, green: 192/255, blue: 54/255)
    static let red = Color(red: 247/255, green: 3/255, blue: 5/255)
    static let pink = Color(red: 254/255, green: 100/255, blue: 205/255)

    static let gradientColors: [Color] = [maroon, darkBlue, lightBlue, yellow, red, pink, maroon]
}

struct TopActionsBar: View {
    var showPlatter: Bool = false
    var expandPlatter: Bool = false
    var cleanedUpCount: Int = 0
    var showGlow: Bool = false
    var personalHidden: Bool = false
    var platterScale: CGFloat = 1.0
    var platterOpacity: CGFloat = 1.0

    @State private var isChevronHovered = false
    @State private var glowRotation: Double = 0

    private let trafficLightWidth: CGFloat = 72

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
                .frame(width: trafficLightWidth)

            // Profile label
            Text("Personal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .opacity(personalHidden ? 0 : 1)

            Spacer()

            // Standalone chevron.down menu + cleanup platter
            HStack(spacing: 0) {
                Text("Cleaned up \(cleanedUpCount) Tabs")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize()
                    .padding(.trailing, -3)
                    .scaleEffect(expandPlatter ? 1 : 0.5, anchor: .trailing)
                    .opacity(expandPlatter ? 1 : 0)
                    .frame(width: expandPlatter ? nil : 0, alignment: .trailing)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if isChevronHovered && !showPlatter {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.5))
                        }
                    }
                    .scaleEffect(expandPlatter ? 1.0 : platterScale)
            }
            .frame(height: 32)
            .background {
                if showPlatter {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.5))
                        .padding(.leading, expandPlatter ? -10 : 0)
                        .scaleEffect(expandPlatter ? 1.0 : platterScale)
                        .opacity(platterOpacity)
                }
            }
            .background {
                if showGlow {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            AngularGradient(
                                colors: DiaChroma.gradientColors,
                                center: .center,
                                angle: .degrees(glowRotation)
                            )
                        )
                        .blur(radius: 8)
                        .opacity(0.1)
                        .scaleEffect(expandPlatter ? 1.15 : 1.15 * platterScale)
                        .padding(.leading, expandPlatter ? -10 : 0)
                }
            }
            .onChange(of: showGlow) { _, active in
                if active {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        glowRotation = 360
                    }
                } else {
                    glowRotation = 0
                }
            }
            .fixedSize()
            .frame(width: 32, height: 32, alignment: .trailing)
            .contentShape(Rectangle())
            .onHover { hovering in
                isChevronHovered = hovering
            }
            .padding(.trailing, 16)
        }
        .frame(height: 14)
        .padding(.top, 17)
    }
}

// MARK: - OpenTabsSection

struct OpenTabsSection: View {
    @Binding var tabs: [TabItem]
    @Binding var selectedTabId: UUID?
    var cleanupIDs: Set<UUID> = []
    var namesFaded = false
    var rowsCollapsed = false

    private func selectTab(_ tab: TabItem) {
        selectedTabId = tab.id
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(tabs.dropLast()) { tab in
                    let isBeingCleaned = cleanupIDs.contains(tab.id)

                    TabRowView(
                        tab: tab,
                        isSelected: tab.id == selectedTabId,
                        onSelect: { selectTab(tab) },
                        nameHidden: isBeingCleaned && namesFaded
                    )
                    .padding(.bottom, isBeingCleaned && rowsCollapsed ? 0 : 4)
                    .frame(height: isBeingCleaned && rowsCollapsed ? 0 : 36)
                    .clipped()
                    .opacity(isBeingCleaned && rowsCollapsed ? 0 : 1)
                }

                if let lastTab = tabs.last {
                    TabRowView(tab: lastTab, isSelected: lastTab.id == selectedTabId) {
                        selectTab(lastTab)
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(.trailing, 6)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

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
