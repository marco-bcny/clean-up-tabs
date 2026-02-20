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
    let finalScale: CGFloat
    let finalRotation: Double
    var fadesOnLanding: Bool = false

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private func positionAt(_ t: CGFloat) -> CGPoint {
        let clamped = max(0, min(1, t))
        let x = startPosition.x + (endPosition.x - startPosition.x) * clamped
        let controlY = min(startPosition.y, endPosition.y) - arcHeight
        let y = pow(1 - clamped, 2) * startPosition.y + 2 * (1 - clamped) * clamped * controlY + pow(clamped, 2) * endPosition.y
        return CGPoint(x: x, y: y)
    }

    private var currentPosition: CGPoint {
        positionAt(min(progress, 1.0))
    }

    private var shadowAmount: CGFloat {
        let t = min(progress, 1.0)
        return sin(.pi * t)
    }

    private var scale: CGFloat {
        if progress > 1.0 {
            let dismissT = min(progress - 1.0, 1.0)
            return finalScale * (1.0 - dismissT)
        }
        let peak: CGFloat = 1.3
        if progress < 0.25 {
            return 1.0 + (progress / 0.25) * (peak - 1.0)
        } else {
            let t = (progress - 0.25) / 0.75
            return peak + (finalScale - peak) * t
        }
    }

    private var rotation: Double {
        finalRotation * min(progress, 1.0)
    }

    private var dismissOpacity: CGFloat {
        if progress > 1.0 {
            let dismissT = min(progress - 1.0, 1.0)
            return 1.0 - dismissT
        }
        // Fade out right at landing for non-stack favicons
        if fadesOnLanding && progress > 0.9 {
            return max(0, 1.0 - (progress - 0.9) / 0.1)
        }
        return 1.0
    }

    private static let baseColors: [Color] = [
        Color(red: 1.0, green: 0.2, blue: 0.3),   // bright red
        Color(red: 1.0, green: 0.4, blue: 0.7),   // hot pink
        Color(red: 0.9, green: 0.2, blue: 0.9),   // magenta
        Color(red: 0.6, green: 0.3, blue: 1.0),   // purple
        Color(red: 0.3, green: 0.5, blue: 1.0),   // blue
        Color(red: 0.1, green: 0.8, blue: 1.0),   // cyan
        Color(red: 0.2, green: 0.9, blue: 0.5),   // green
        Color(red: 0.6, green: 1.0, blue: 0.2),   // lime
        Color(red: 1.0, green: 0.95, blue: 0.2),  // yellow
        Color(red: 1.0, green: 0.7, blue: 0.1),   // orange
        Color(red: 1.0, green: 0.4, blue: 0.2),   // red-orange
        Color(red: 1.0, green: 0.3, blue: 0.55),  // rose
    ]

    // Deterministic pseudo-random from seed
    private static func hash(_ seed: Double) -> Double {
        let x = sin(seed * 127.1 + 311.7) * 43758.5453
        return x - x.rounded(.down)
    }

    func body(content: Content) -> some View {
        ZStack {
            // Rainbow cloud trail along flight path
            if progress > 0.01 && progress <= 1.0 {
                let landingFade: CGFloat = progress < 0.75 ? 1.0 : max(0, (1.0 - progress) / 0.25)

                // Cloud grows over the flight and fades out toward the end
                let cloudScale: CGFloat = 0.5 + progress * 2.0
                let cloudFade: CGFloat = progress < 0.5 ? 1.0 : max(0, (1.0 - progress) / 0.5)

                ForEach(0..<20, id: \.self) { i in
                    let h = Self.hash(Double(i))

                    // Each blob trails behind the favicon along the path
                    let trailT = progress - CGFloat(i) * 0.02
                    let visible = trailT > 0
                    let pos = positionAt(max(0, trailT))

                    // Fade with distance from favicon
                    let age = CGFloat(i) * 0.02
                    let fade = max(0, 1.0 - Double(age) / 0.4)

                    // Size grows as animation progresses
                    let baseSize: CGFloat = 35 + CGFloat(h) * 25
                    let size = baseSize * cloudScale

                    Circle()
                        .fill(Self.baseColors[i % Self.baseColors.count])
                        .frame(width: size, height: size)
                        .blur(radius: 18 * cloudScale)
                        .opacity(visible ? fade * 0.04 * cloudFade * landingFade : 0)
                        .position(pos)
                }
            }

            // Main content
            content
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(dismissOpacity)
                .shadow(
                    color: .black.opacity(0.3 * shadowAmount),
                    radius: 20 * shadowAmount,
                    y: 2
                )
                .position(currentPosition)
        }
    }
}

// MARK: - Flying Favicon Data

struct FlyingFaviconItem: Identifiable {
    let id: UUID
    let favicon: TabItem.FaviconType
    let startPosition: CGPoint
    let stackIndex: Int
    let stackCount: Int
}

// MARK: - SidebarView

struct SidebarView: View {
    let pinnedTabs: [TabItem]
    @Binding var openTabs: [TabItem]
    @Binding var selectedTabId: UUID?
    var cleanupTrigger: Int = 0

    // Cleanup animation state
    @State private var cleanupIDs: Set<UUID> = []
    @State private var collapsedIDs: Set<UUID> = []
    @State private var fadedNameIDs: Set<UUID> = []
    @State private var launchedIDs: Set<UUID> = []
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
    @State private var platterOpacity: CGFloat = 1.0
    @State private var strokeTrim: CGFloat = 0
    @State private var strokeOpacity: CGFloat = 1.0

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
                platterScale: platterScale,
                platterOpacity: platterOpacity,
                strokeTrim: strokeTrim,
                strokeOpacity: strokeOpacity
            )

            PinnedTabsView(tabs: pinnedTabs)
                .padding(.leading, 6)
                .padding(.top, 6)

            OpenTabsSection(
                tabs: $openTabs,
                selectedTabId: $selectedTabId,
                cleanupIDs: cleanupIDs,
                collapsedIDs: collapsedIDs,
                fadedNameIDs: fadedNameIDs,
                launchedIDs: launchedIDs
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
        .overlay(alignment: .topLeading) {
            let stackAngles: [Double] = [-8, 5, -12, 9, -4, 13, -10, 7, -14, 11]

            ZStack(alignment: .topLeading) {
            ForEach(flyingItems) { item in
                let finalScale: CGFloat = item.stackCount > 1
                    ? 0.7 + 0.15 * CGFloat(item.stackIndex) / CGFloat(item.stackCount - 1)
                    : 0.85
                let finalRotation = item.stackCount > 1
                    ? stackAngles[item.stackIndex % stackAngles.count]
                    : 0.0

                // Shadow fades from 10% (top) to 0% over ~4 items from the top
                let distFromTop = item.stackCount - 1 - item.stackIndex
                let shadowOpacity = max(0, 0.10 - 0.10 * CGFloat(distFromTop) / 3.0)

                let cardProgress = flightProgress[item.id] ?? 0
                let cardOpacity = min(1.0, cardProgress / 0.15)

                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(shadowOpacity), radius: 2, y: 2)
                        .opacity(cardOpacity)
                    FaviconView(favicon: item.favicon, size: 16)
                }
                .modifier(ArcFlightModifier(
                    progress: flightProgress[item.id] ?? 0,
                    startPosition: item.startPosition,
                    endPosition: flightEndPosition,
                    arcHeight: 80,
                    finalScale: finalScale,
                    finalRotation: finalRotation,
                    fadesOnLanding: item.stackIndex < item.stackCount - 3
                ))
            }
            }
            .frame(width: 800, height: 1200)
            .allowsHitTesting(false)
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

        let dismissDuration = 0.2

        // Phase 1: Label collapses + entire stack dismisses simultaneously
        withAnimation(.easeOut(duration: dismissDuration)) {
            expandPlatter = false
            personalHidden = false
            showGlow = false
            strokeTrim = 0
            strokeOpacity = 1.0
            for item in flyingItems {
                flightProgress[item.id] = 2.0
            }
        }

        // Phase 2: Background fades out once it's back to square size
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration) {
            withAnimation(.easeOut(duration: 0.1)) {
                platterOpacity = 0
                chevronOpacity = 1.0
            }
        }

        // Phase 3: Restore tabs
        let cleanupTime = dismissDuration + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + cleanupTime) {
            showPlatter = false
            platterOpacity = 1.0
            flyingItems = []
            flightProgress = [:]
            withAnimation(.easeInOut(duration: 0.35)) {
                openTabs = saved
            }
            savedTabs = nil
            hasCleanedUp = false
        }
    }

    // MARK: - Dismiss Platter

    private func dismissPlatter() {
        let dismissDuration = 0.2

        // Phase 1: Label collapses + entire stack dismisses simultaneously
        withAnimation(.easeOut(duration: dismissDuration)) {
            expandPlatter = false
            personalHidden = false
            showGlow = false
            strokeTrim = 0
            strokeOpacity = 1.0
            for item in flyingItems {
                flightProgress[item.id] = 2.0
            }
        }

        // Phase 2: Background fades out once it's back to square size
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration) {
            withAnimation(.easeOut(duration: 0.1)) {
                platterOpacity = 0
                chevronOpacity = 1.0
            }
        }

        // Phase 3: Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration + 0.15) {
            showPlatter = false
            platterOpacity = 1.0
            flyingItems = []
            flightProgress = [:]
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
        flightEndPosition = CGPoint(x: chevronRect.midX, y: chevronRect.midY)

        // Collect tabs to remove in order
        let tabsToRemove = openTabs.filter { idsToRemove.contains($0.id) }
        let totalCount = tabsToRemove.count

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

        // Fade out chevron as first favicon approaches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeOut(duration: 0.2)) {
                chevronOpacity = 0
            }
        }

        // Phase 3b: Fly favicons (staggered) — each launches from its current row position
        for (index, tab) in tabsToRemove.enumerated() {
            let delay = 0.15 + Double(index) * 0.12
            flightProgress[tab.id] = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Capture current position at launch time
                let startPos: CGPoint
                if let rect = tabPositions[tab.id] {
                    startPos = CGPoint(x: rect.minX + 18, y: rect.midY)
                } else {
                    startPos = flightEndPosition
                }

                let item = FlyingFaviconItem(
                    id: tab.id,
                    favicon: tab.favicon,
                    startPosition: startPos,
                    stackIndex: index,
                    stackCount: totalCount
                )
                flyingItems.append(item)
                launchedIDs.insert(tab.id)

                // Fade out tab name
                withAnimation(.easeOut(duration: 0.3)) {
                    fadedNameIDs.insert(tab.id)
                }

                // Collapse this row as its favicon launches
                withAnimation(.easeInOut(duration: 0.4)) {
                    collapsedIDs.insert(tab.id)
                }

                withAnimation(.easeInOut(duration: 0.69)) {
                    flightProgress[tab.id] = 1.0
                }
            }
        }

        // Phase 5a: Remove tabs after they fully land (keep stack visible)
        let lastDelay = Double(max(0, totalCount - 1)) * 0.12
        let allLandTime = 0.15 + lastDelay + 0.69 + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + allLandTime) {
            // Remove tabs while they're still collapsed (height 0), then reset state
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                openTabs.removeAll { idsToRemove.contains($0.id) }
            }

            // Reset cleanup state after removal so remaining rows aren't affected
            cleanupIDs = []
            collapsedIDs = []
            fadedNameIDs = []
            launchedIDs = []
        }

        // Start rainbow stroke 1s before second favicon lands
        let secondLandTime = 0.15 + Double(min(1, totalCount - 1)) * 0.12 + 0.69
        let strokeStart = max(0.05, secondLandTime - 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + strokeStart) {
            strokeTrim = 0
            strokeOpacity = 1.0
            withAnimation(.linear(duration: 2.0)) {
                strokeTrim = 4.0
            }
            // Fade stroke out well before it stops
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    strokeOpacity = 0
                }
            }
        }

        // Phase 5b: Expand platter to reveal label as favicons start flying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expandPlatter = true
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

// MARK: - Rainbow Stroke

struct RainbowStrokeView: View, Animatable {
    var progress: CGFloat
    var rotation: Double
    let cornerRadius: CGFloat

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let segmentLength: CGFloat = 1.0 / 3.0
        let leading = progress - segmentLength
        let from = leading.truncatingRemainder(dividingBy: 1.0)
        let to = progress.truncatingRemainder(dividingBy: 1.0)
        let normalizedFrom = from < 0 ? from + 1.0 : from
        let normalizedTo = to <= 0 && progress > 0 ? 1.0 : (to < 0 ? to + 1.0 : to)
        let wraps = normalizedFrom >= normalizedTo

        ZStack {
            if wraps {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .trim(from: normalizedFrom, to: 1.0)
                    .stroke(
                        AngularGradient(
                            colors: DiaChroma.gradientColors,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .trim(from: 0, to: normalizedTo)
                    .stroke(
                        AngularGradient(
                            colors: DiaChroma.gradientColors,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .trim(from: normalizedFrom, to: normalizedTo)
                    .stroke(
                        AngularGradient(
                            colors: DiaChroma.gradientColors,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .padding(-1.5)
    }
}

struct TopActionsBar: View {
    var showPlatter: Bool = false
    var expandPlatter: Bool = false
    var chevronOpacity: CGFloat = 1.0
    var cleanedUpCount: Int = 0
    var showGlow: Bool = false
    var personalHidden: Bool = false
    var platterScale: CGFloat = 1.0
    var platterOpacity: CGFloat = 1.0
    var strokeTrim: CGFloat = 0
    var strokeOpacity: CGFloat = 1.0

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
                    .opacity(showPlatter ? chevronOpacity : 1.0)
                    .scaleEffect(showPlatter ? (0.5 + 0.5 * chevronOpacity) : 1.0)
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
                        .opacity(platterOpacity)
                }
            }
            .overlay {
                RainbowStrokeView(
                    progress: strokeTrim,
                    rotation: glowRotation,
                    cornerRadius: 12
                )
                .padding(.leading, expandPlatter ? -8 : 0)
                .opacity(strokeTrim > 0 ? strokeOpacity * 0.5 : 0)
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
    var collapsedIDs: Set<UUID> = []
    var fadedNameIDs: Set<UUID> = []
    var launchedIDs: Set<UUID> = []

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
                        nameHidden: fadedNameIDs.contains(tab.id),
                        faviconHidden: launchedIDs.contains(tab.id)
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
                    .padding(.bottom, collapsedIDs.contains(tab.id) ? 0 : 4)
                    .frame(height: collapsedIDs.contains(tab.id) ? 0 : 36)
                    .clipped()
                    .opacity(collapsedIDs.contains(tab.id) ? 0 : 1)
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
