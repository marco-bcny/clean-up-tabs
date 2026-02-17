# CleanUp Demo — Implementation Plan

A SwiftUI macOS app simulating a browser sidebar with a "cleanup" animation that removes duplicate and inactive tabs.

## App Structure

### Files

| File | Purpose |
|------|---------|
| `ContentView.swift` | Root view. Contains `DiaMainView` which lays out sidebar + web content in an `HStack`. Click or press Return on the web content area triggers cleanup. Uses `VisualEffectBlur` (sidebar material) as window background. |
| `Models/TabItem.swift` | `TabItem` model with `id`, `title`, `favicon` (enum `FaviconType`), `isSelected`, `isPinned`. Contains sample data for pinned and open tabs. FaviconType cases: `.systemSymbol`, `.remote`, `.dia`, `.google`, `.slack`, `.youtube`, `.wikipedia`, `.reddit`, `.pitchfork`, `.verge`, `.architecturalDigest`, `.designWithinReach`, `.polygon`, `.nyt`, `.onShoes`, `.nike`. |
| `Components/SidebarView.swift` | **Main animation file.** Contains all cleanup animation logic, preference keys, arc flight modifier, flying favicon overlay, top actions bar, and open tabs section. |
| `Components/FaviconView.swift` | Renders favicons by type — asset images, system symbols, or remote URLs. `.dia` favicon has `brightness(-0.15)`. |
| `Components/TabRowView.swift` | Single tab row: favicon + title, hover/selected background states. 32pt height (16pt content + 16pt vertical padding). Has `nameHidden` and `faviconHidden` flags for cleanup animation. |
| `Components/PinnedTabsView.swift` | 4-column grid of pinned tab cells with hover state. |
| `Components/WebContentsView.swift` | Mock web pages for each favicon type (YouTube, Wikipedia, NYT, Google, Reddit, etc.). New Tab shows Dia logo + command bar. |
| `Components/CommandBarView.swift` | Search/command bar on new tab page. |
| `Components/URLBarView.swift` | URL bar at top of web content area. |
| `Components/TabSearchMenuView.swift` | Tab search overlay menu. |
| `Components/WindowStandardButtons.swift` | Traffic light window buttons. |

### Assets

- Favicon images: `favicon-google`, `favicon-slack`, `favicon-youtube`, `favicon-wikipedia`, `favicon-reddit`, `favicon-pitchfork`, `favicon-verge`, `favicon-architecturaldesign`, `favicon-designwithinreach`, `favicon-polygon`, `favicon-nyt`, `favicon-onshoes`, `favicon-nike`, `favicon-dia`
- `dialogo` — Dia logo for new tab page

---

## Cleanup Animation — Detailed Specification

### Overview

When triggered (click web content area or press Return), the animation:
1. Identifies tabs to remove (inactive "New Tab" pages + duplicates by title, keeping the **last** occurrence)
2. Fades tab names, collapses rows, flies favicons along an arc into an overflow menu
3. Shows a "Cleaned up N Tabs" label with a chroma glow
4. Auto-dismisses after 3 seconds
5. Clicking again restores the original tabs

### Duplicate Detection Logic

```swift
// Remove all "New Tab" (not selected, not the + button)
// For other titles: keep LAST occurrence, remove earlier duplicates
var seen: [String: UUID] = [:]
for tab in allTabs.reversed() where tab.title != "New Tab" {
    if seen[tab.title] != nil {
        idsToRemove.insert(tab.id)
    } else {
        seen[tab.title] = tab.id
    }
}
```

### Position Tracking

- `TabPositionKey` (PreferenceKey): tracks each tab row's frame in the `"sidebar"` coordinate space
- `ChevronPositionKey` (PreferenceKey): tracks the chevron.down button's frame
- Positions are used to compute flight start/end points

### Animation Phases

#### Phase 1 — Fade tab names (t=0)
- `namesFaded = true`
- Duration: 0.3s ease-out
- Tab titles of cleanup targets fade to 0

#### Phase 2 — Collapse rows (t=0.15s)
- `rowsCollapsed = true`
- Duration: 0.4s ease-in-out
- Each cleanup row: height 36→0, padding.bottom 4→0, opacity→0, `.clipped()`
- VStack spacing is 0; spacing is handled via per-row `.padding(.bottom, 4)`

#### Phase 3 — Show overflow platter + glow (t=0.15s)
- `showPlatter = true`, `showGlow = true` (0.25s ease-out)
- `platterScale = 1.28` (0.45s ease-out) — overflow menu scales up
- Rotating chroma glow appears (AngularGradient with DiaChroma colors, 4s linear rotation)

#### Phase 3b — Fly favicons (staggered, starting at t=0.15s)
- Each favicon launches 0.06s apart
- At launch time, captures the tab's **current** position from `tabPositions` (accounts for row collapse)
- Creates a `FlyingFaviconItem` with startPosition, stackIndex, stackCount
- Flight animation: 0.69s ease-in-out, `flightProgress` goes 0→1.0
- `launchedIDs` tracks which favicons have launched (hides them in the tab row)

#### Scale hold + bounce down (t=0.15 + 0.45 + 0.5 = 1.1s)
- `platterScale = 1.0` with spring(response: 0.45, dampingFraction: 0.6)

#### Chevron fade (t=0.75s)
- `chevronOpacity = 0` (0.2s ease-out)
- Chevron also scales down as it fades: `scaleEffect(0.5 + 0.5 * chevronOpacity)`

#### Phase 5a — Remove tabs (after all land)
- `allLandTime = 0.15 + lastStaggerDelay + 0.69 + 0.15`
- Remove tabs with `disablesAnimations` transaction (instant, no layout jump)
- Reset cleanup state: `cleanupIDs`, `namesFaded`, `rowsCollapsed`, `launchedIDs`

#### Phase 5b — Show label (t=0.25s)
- `expandPlatter = true`, `personalHidden = true`
- Spring(response: 0.4, dampingFraction: 0.85)
- Label: "Cleaned up N Tabs" — scales from 0.5→1.0, opacity 0→1, width 0→auto
- Background extends with `.padding(.leading, -8)` when expanded

#### Phase 6 — Auto-dismiss (3s after label appears)
- Calls `dismissPlatter()`

### Dismiss Animation (0.2s)

1. **All at once** (0.2s ease-out):
   - `expandPlatter = false` — label collapses
   - `personalHidden = false` — "Personal" label returns
   - `showGlow = false` — chroma glow fades
   - All flying items: `flightProgress = 2.0` — stack shrinks to 0 (dismiss phase in ArcFlightModifier)

2. **After 0.2s** (0.1s ease-out):
   - `platterOpacity = 0` — background fades
   - `chevronOpacity = 1.0` — chevron returns (also scales back up)

3. **After 0.35s**: Clean up all state

### Restore Animation

Same as dismiss, but after cleanup also restores `openTabs` from `savedTabs` with a 0.35s ease-in-out animation.

---

## ArcFlightModifier — Detailed Spec

An `Animatable ViewModifier` that moves content along a quadratic bezier arc.

### Parameters
- `progress`: 0→1.0 (flight), >1.0 (dismiss phase)
- `startPosition`, `endPosition`: flight endpoints
- `arcHeight`: 80pt — how high above the straight line the arc peaks
- `finalScale`: where the favicon settles (0.7–0.85 depending on stack position)
- `finalRotation`: angle in degrees at landing (from `stackAngles` array)
- `fadesOnLanding`: if true, favicon fades out from progress 0.5→1.0 (for non-stack items)

### Bezier Path
```
controlY = min(startY, endY) - arcHeight
y = (1-t)² * startY + 2(1-t)t * controlY + t² * endY
x = linear interpolation
```

### Scale Curve
- 0→0.25: ramp 1.0→1.3 (peak)
- 0.25→1.0: ease from 1.3→finalScale
- >1.0 (dismiss): finalScale→0

### Rotation
- Linear: 0→finalRotation over progress 0→1.0
- Clamped at 1.0 during dismiss

### Shadow
- `sin(π * progress)` — peaks at midpoint, zero at start/end
- Color: black 30%, radius 20pt, y-offset 2pt

### Dismiss (progress > 1.0)
- Scale shrinks to 0
- Opacity fades to 0

### Rainbow Cloud Trail
- 20 large, heavily blurred colored circles along the bezier path behind the favicon
- Each blob at `progress - i * 0.02` on the path
- **Cloud growth**: starts at 50% size, grows to 250% over flight (`0.5 + progress * 2.0`)
- **Cloud fade**: starts fading at 50% of flight, fully gone by landing
- **Landing fade**: additional fade in last 25% of flight
- Base blob sizes: 35–60pt (random per blob)
- Blur radius: 18pt × cloudScale
- Opacity: `fade * 0.06 * cloudFade * landingFade`
- 12 vivid rainbow colors cycling: bright red, hot pink, magenta, purple, blue, cyan, green, lime, yellow, orange, red-orange, rose

### Flying Favicon Visual
- White rounded rect card (20×20, cornerRadius 4) behind 16×16 favicon
- Shadow: 10% on frontmost, fading to 0% over ~4 items deep
- Stack angles: `[-8, 5, -12, 9, -4, 13, -10, 7, -14, 11]` degrees
- Scale: 0.7 (back) to 0.85 (front) in the stack
- All but last 3 favicons fade out as they approach landing

### Overlay Rendering
- Overlay uses `alignment: .topLeading` with a `ZStack` sized 800×1200
- This prevents the rainbow cloud from being cropped by the sidebar's 249pt width
- `allowsHitTesting(false)` so it doesn't interfere with clicks

---

## TopActionsBar — Spec

- HStack: traffic light spacer (72pt) | "Personal" label | Spacer | overflow menu | 16pt trailing padding
- Height: 14pt, top padding: 17pt

### Overflow Menu (chevron.down)
- Frame: 32×32pt (64px @2x), cornerRadius 12
- Hover state: white 50% fill
- During animation:
  - Chevron fades + scales down (opacity-linked scale: `0.5 + 0.5 * opacity`)
  - Background: white 50% rounded rect, extends left with `-8pt` padding when label visible
  - Scales with `platterScale` (up to 1.28×) when label is NOT expanded
  - Scale anchor: center of chevron (label extends rightward via `.fixedSize()` + `frame(width: 32, alignment: .trailing)`)

### Label: "Cleaned up N Tabs"
- Font: system 11pt medium
- Appears with scale 0.5→1.0 (anchor: `.trailing`) + opacity 0→1
- Width: 0→auto (`.frame(width: expandPlatter ? nil : 0)`)
- Spacing: -3pt trailing padding between label and chevron

### Chroma Glow
- AngularGradient with DiaChroma colors (maroon, darkBlue, lightBlue, yellow, red, pink)
- Blur: 8pt, opacity: 0.2
- Scale: 1.15× the platter size
- Rotation: continuous 360° over 4s (linear, repeating)

---

## DiaChroma Colors

```swift
maroon:    rgb(106, 23, 49)
darkBlue:  rgb(51, 76, 180)
lightBlue: rgb(45, 129, 255)
yellow:    rgb(205, 192, 54)
red:       rgb(247, 3, 5)
pink:      rgb(254, 100, 205)
```

---

## Key Timing Summary

| Time | Event |
|------|-------|
| 0.00s | Fade tab names (0.3s) |
| 0.15s | Collapse rows (0.4s), show platter + glow, start scale-up (0.45s), begin staggered favicon flights |
| 0.25s | Expand platter, show "Cleaned up N Tabs" label |
| 0.75s | Fade chevron (0.2s) |
| 1.10s | Scale bounce back to 1.0 (spring) |
| ~1.5s | All favicons landed, remove tabs from data |
| 3.25s | Auto-dismiss (0.2s label collapse + stack shrink, then 0.1s background fade) |

---

## Layout Details

- Sidebar width: 249pt
- Tab row height: 36pt (32pt content + 4pt bottom spacing)
- VStack spacing: 0 (spacing handled per-row)
- Pinned tabs: 4-column grid, 40pt cell height
- Window background: `NSVisualEffectView` with `.sidebar` material
- Web content: white 70% opacity, 8pt corner radius, 6pt padding (top, trailing, bottom)
