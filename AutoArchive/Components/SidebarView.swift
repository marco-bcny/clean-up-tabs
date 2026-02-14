//
//  SidebarView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

// MARK: - Preference Keys

struct TabPositionKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct ChevronPositionKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

// MARK: - Arc Flight Modifier

struct ArcFlightModifier: ViewModifier, Animatable {
    var progress: CGFloat
    let startPosition: CGPoint
    let endPosition: CGPoint
    let arcHeight: CGFloat

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var currentPosition: CGPoint {
        let t = progress
        let x = startPosition.x + (endPosition.x - startPosition.x) * t
        let controlY = min(startPosition.y, endPosition.y) - arcHeight
        let y = pow(1 - t, 2) * startPosition.y + 2 * (1 - t) * t * controlY + pow(t, 2) * endPosition.y
        return CGPoint(x: x, y: y)
    }

    private var shadowAmount: CGFloat {
        sin(.pi * progress)
    }

    private var scale: CGFloat {
        if progress < 0.3 {
            // Scale up to 2.0x in the first 30%
            return 1.0 + (progress / 0.3) * 1.0
        } else if progress < 0.65 {
            // Ease back to 1.0
            let t = (progress - 0.3) / 0.35
            return 2.0 - t * 1.0
        } else {
            // Scale down into the chevron
            return 1.0 - ((progress - 0.65) / 0.35) * 0.25
        }
    }

    private var fadeOpacity: CGFloat {
        progress > 0.75 ? 1.0 - (progress - 0.75) / 0.25 : 1.0
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(fadeOpacity)
            .shadow(
                color: .black.opacity(0.3 * shadowAmount),
                radius: 20 * shadowAmount,
                y: 2
            )
            .position(currentPosition)
    }
}

// MARK: - Flying Favicon Data

struct FlyingFaviconItem: Identifiable {
    let id: UUID
    let favicon: TabItem.FaviconType
    let startPosition: CGPoint
}

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
    @State private var faviconsFired = false
    @State private var cleanedUpCount = 0
    @State private var hasCleanedUp = false
    @State private var isAnimating = false

    // Saved state for restore
    @State private var savedTabs: [TabItem]? = nil

    // Platter state
    @State private var showPlatter = false
    @State private var expandPlatter = false
    @State private var chevronOpacity: CGFloat = 1.0
    @State private var showGlow = false
    @State private var personalHidden = false
    @State private var platterScale: CGFloat = 1.0

    // Position tracking
    @State private var tabPositions: [UUID: CGRect] = [:]
    @State private var chevronRect: CGRect = .zero
    @State private var flightEndPosition: CGPoint = .zero

    // Flying favicons
    @State private var flyingItems: [FlyingFaviconItem] = []
    @State private var flightProgress: [UUID: CGFloat] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TopActionsBar(
                showPlatter: showPlatter,
                expandPlatter: expandPlatter,
                chevronOpacity: chevronOpacity,
                cleanedUpCount: cleanedUpCount,
                showGlow: showGlow,
                personalHidden: personalHidden,
                platterScale: platterScale
            )

            PinnedTabsView(tabs: pinnedTabs)
                .padding(.leading, 6)
                .padding(.top, 6)

            OpenTabsSection(
                tabs: $openTabs,
                selectedTabId: $selectedTabId,
                cleanupIDs: cleanupIDs,
                namesFaded: namesFaded,
                rowsCollapsed: rowsCollapsed,
                faviconsFired: faviconsFired
            )
            .padding(.leading, 6)
        }
        .frame(width: 249)
        .coordinateSpace(name: "sidebar")
        .onPreferenceChange(TabPositionKey.self) { tabPositions = $0 }
        .onPreferenceChange(ChevronPositionKey.self) { chevronRect = $0 }
        .onChange(of: cleanupTrigger) {
            handleToggle()
        }
        .overlay {
            ForEach(flyingItems) { item in
                let liveStart = tabPositions[item.id].map {
                    CGPoint(x: $0.minX + 18, y: $0.midY)
                } ?? item.startPosition

                FaviconView(favicon: item.favicon, size: 16)
                    .modifier(ArcFlightModifier(
                        progress: flightProgress[item.id] ?? 0,
                        startPosition: liveStart,
                        endPosition: flightEndPosition,
                        arcHeight: 80
                    ))
            }
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

        // Phase 1: Collapse text and fade background simultaneously
        withAnimation(.easeOut(duration: 0.2)) {
            expandPlatter = false
            personalHidden = false
            showPlatter = false
            showGlow = false
        }

        // Phase 2: Restore tabs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.35)) {
                openTabs = saved
            }
            savedTabs = nil
            hasCleanedUp = false
        }
    }

    // MARK: - Dismiss Platter

    private func dismissPlatter() {
        // Collapse text and fade background simultaneously
        withAnimation(.easeOut(duration: 0.25)) {
            expandPlatter = false
            personalHidden = false
            showPlatter = false
            showGlow = false
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

        // Duplicates by title (keep first occurrence)
        var seen: [String: UUID] = [:]
        for tab in allTabs where tab.title != "New Tab" {
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
        flightEndPosition = CGPoint(x: chevronRect.midX, y: chevronRect.midY)

        // Build flying items from current positions
        var items: [FlyingFaviconItem] = []
        for tab in openTabs where idsToRemove.contains(tab.id) {
            if let rect = tabPositions[tab.id] {
                items.append(FlyingFaviconItem(
                    id: tab.id,
                    favicon: tab.favicon,
                    startPosition: CGPoint(x: rect.minX + 18, y: rect.midY)
                ))
                flightProgress[tab.id] = 0
            }
        }
        flyingItems = items

        // Phase 1: Fade names
        withAnimation(.easeOut(duration: 0.3)) {
            namesFaded = true
        }

        // Phase 1b: Fire favicons (hide originals, show overlays)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            faviconsFired = true
        }

        // Phase 2: Collapse rows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                rowsCollapsed = true
            }
        }

        // Phase 3: Show platter + glow as favicons start flying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) {
                showPlatter = true
                showGlow = true
            }
            withAnimation(.easeOut(duration: 0.45)) {
                platterScale = 1.28
            }
        }

        // Scale back down with bounce after scale-up + hold
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + 0.45 + 0.5) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                platterScale = 1.0
            }
        }

        // Phase 3b: Fly favicons (staggered)
        for (index, item) in items.enumerated() {
            let delay = 0.15 + Double(index) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.81)) {
                    flightProgress[item.id] = 1.0
                }
            }
        }

        // Phase 5a: Clean up flying favicons after they fully land
        let lastDelay = Double(max(0, items.count - 1)) * 0.06
        let allLandTime = 0.15 + lastDelay + 0.81 + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + allLandTime) {
            flyingItems = []
            flightProgress = [:]

            // Remove tabs while they're still collapsed (height 0), then reset state
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                openTabs.removeAll { idsToRemove.contains($0.id) }
            }

            // Reset cleanup state after removal so remaining rows aren't affected
            cleanupIDs = []
            namesFaded = false
            rowsCollapsed = false
            faviconsFired = false
        }

        // Phase 5b: Expand platter to reveal label 0.6s after favicons land
        DispatchQueue.main.asyncAfter(deadline: .now() + allLandTime - 0.05) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expandPlatter = true
                chevronOpacity = 1.0
                personalHidden = true
            }

            hasCleanedUp = true
            isAnimating = false

            // Phase 6: Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissPlatter()
            }
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
    var chevronOpacity: CGFloat = 1.0
    var cleanedUpCount: Int = 0
    var showGlow: Bool = false
    var personalHidden: Bool = false
    var platterScale: CGFloat = 1.0

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
                    .opacity(expandPlatter ? 1 : 0)
                    .frame(width: expandPlatter ? nil : 0, alignment: .trailing)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .opacity(expandPlatter ? chevronOpacity : 1.0)
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
                        .padding(.leading, expandPlatter ? -8 : 0)
                        .scaleEffect(expandPlatter ? 1.0 : platterScale)
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
                        .opacity(0.2)
                        .scaleEffect(expandPlatter ? 1.15 : 1.15 * platterScale)
                        .padding(.leading, expandPlatter ? -8 : 0)
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
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ChevronPositionKey.self,
                            value: geo.frame(in: .named("sidebar"))
                        )
                }
            )
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
    var faviconsFired = false

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
                        nameHidden: isBeingCleaned && namesFaded,
                        faviconHidden: isBeingCleaned && faviconsFired
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: TabPositionKey.self,
                                    value: [tab.id: geo.frame(in: .named("sidebar"))]
                                )
                        }
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
