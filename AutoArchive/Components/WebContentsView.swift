//
//  WebContentsView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct WebContentsView: View {
    var selectedTab: TabItem?

    var body: some View {
        VStack(spacing: 0) {
            URLBarView()

            // Website content area
            ZStack {
                if let tab = selectedTab {
                    pageContent(for: tab)
                } else {
                    // Default new tab view
                    newTabContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var newTabContent: some View {
        VStack {
            Spacer()
                .frame(height: 202)

            DiaLargeLogo()
                .frame(width: 52, height: 43)

            Spacer()
                .frame(height: 36)

            CommandBarView()

            Spacer()
        }
    }

    @ViewBuilder
    private func pageContent(for tab: TabItem) -> some View {
        switch tab.favicon {
        case .dia:
            newTabContent
        case .systemSymbol(let name) where name == "plus":
            newTabContent
        case .youtube:
            YouTubePageView(title: tab.title)
        case .wikipedia:
            WikipediaPageView(title: tab.title)
        case .nyt:
            NYTPageView(title: tab.title)
        case .google:
            GooglePageView(title: tab.title)
        case .reddit:
            RedditPageView(title: tab.title)
        case .verge:
            TheVergePageView(title: tab.title)
        case .polygon:
            PolygonPageView(title: tab.title)
        case .pitchfork:
            PitchforkPageView(title: tab.title)
        case .architecturalDigest:
            ArchitecturalDigestPageView(title: tab.title)
        case .designWithinReach:
            DesignWithinReachPageView(title: tab.title)
        case .nike:
            NikePageView(title: tab.title)
        case .onShoes:
            OnShoesPageView(title: tab.title)
        default:
            GenericPageView(title: tab.title)
        }
    }
}

// MARK: - Mock Page Views

struct YouTubePageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // YouTube header bar
            HStack {
                Image("favicon-youtube")
                    .resizable()
                    .frame(width: 90, height: 20)
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                    Image(systemName: "bell")
                    Circle()
                        .fill(.blue)
                        .frame(width: 32, height: 32)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            // Video content
            VStack(alignment: .leading, spacing: 16) {
                // Video player placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))

                HStack {
                    Text("NPR Music")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("8.2M views")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct WikipediaPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Wikipedia header
            HStack {
                VStack(alignment: .leading) {
                    Text("WIKIPEDIA")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                    Text("The Free Encyclopedia")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Text("Article")
                    Text("Talk")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13))
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title.replacingOccurrences(of: " - Wikipedia", with: ""))
                        .font(.system(size: 28, weight: .bold, design: .serif))

                    Text("From Wikipedia, the free encyclopedia")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text("This article covers the history, significance, and modern interpretations of the subject. The topic has been influential in various fields including art, architecture, and design philosophy.")
                        .font(.system(size: 15, design: .serif))
                        .lineSpacing(4)

                    Text("The movement emerged in the early 20th century and continues to influence contemporary thought and practice around the world.")
                        .font(.system(size: 15, design: .serif))
                        .lineSpacing(4)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct NYTPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // NYT header
            VStack(spacing: 8) {
                Text("The New York Times")
                    .font(.custom("Times New Roman", size: 28))
                    .fontWeight(.bold)

                Divider()

                HStack {
                    ForEach(["U.S.", "World", "Business", "Arts", "Opinion"], id: \.self) { section in
                        Text(section)
                            .font(.system(size: 12))
                        if section != "Opinion" {
                            Text("|")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main headline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feature")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red)

                        Text(title.replacingOccurrences(of: " - NYT", with: ""))
                            .font(.system(size: 24, weight: .bold, design: .serif))

                        Text("An in-depth look at the trends shaping our world, with analysis from our reporters and experts.")
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct GooglePageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Google header
            HStack {
                Image("favicon-google")
                    .resizable()
                    .frame(width: 92, height: 30)
                Spacer()
                Circle()
                    .fill(.blue)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .background(Color.white)

            Divider()

            // Search results
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("About 1,240,000,000 results (0.42 seconds)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top)

                    // Sample search results
                    ForEach(0..<5) { i in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("www.example\(i + 1).com")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text("Search Result \(i + 1) - Relevant Content")
                                .font(.system(size: 18))
                                .foregroundStyle(.blue)
                            Text("This is a preview of the search result content that would appear in Google search results...")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RedditPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Reddit header
            HStack {
                Image("favicon-reddit")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text("reddit")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.orange)
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                    Image(systemName: "bell")
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            // Post content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading) {
                            Text(title.contains("r/") ? String(title.split(separator: " - ").first ?? "") : "r/popular")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Posted by u/username • 5 hours ago")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(title.contains(" - ") ? String(title.split(separator: " - ").last ?? "") : title)
                        .font(.system(size: 20, weight: .semibold))

                    Text("This is an interesting discussion about the topic. Many community members have shared their thoughts and experiences...")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        HStack {
                            Image(systemName: "arrow.up")
                            Text("2.4k")
                            Image(systemName: "arrow.down")
                        }
                        HStack {
                            Image(systemName: "bubble.left")
                            Text("342 Comments")
                        }
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct TheVergePageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // The Verge header
            HStack {
                Text("THE VERGE")
                    .font(.system(size: 18, weight: .black))
                Spacer()
                HStack(spacing: 16) {
                    Text("Tech")
                    Text("Reviews")
                    Text("Science")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Article image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(16/9, contentMode: .fit)

                    Text(title.replacingOccurrences(of: " - The Verge", with: ""))
                        .font(.system(size: 28, weight: .bold))

                    HStack {
                        Text("By Staff Writer")
                            .font(.system(size: 13))
                        Text("•")
                        Text("Jan 24, 2026")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)

                    Text("The latest in technology news and reviews. Our team has spent weeks testing and evaluating to bring you this comprehensive coverage...")
                        .font(.system(size: 16))
                        .lineSpacing(4)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct PolygonPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Polygon header
            HStack {
                Text("POLYGON")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.purple)
                Spacer()
                HStack(spacing: 16) {
                    Text("News")
                    Text("Reviews")
                    Text("Guides")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Game image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.1))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.purple.opacity(0.3))
                        }

                    Text(title.replacingOccurrences(of: " - Polygon", with: ""))
                        .font(.system(size: 26, weight: .bold))

                    HStack {
                        Text("Review")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                        Text("By Gaming Editor • Jan 24, 2026")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Text("Our definitive review of this highly anticipated release. We've played through the entire experience to give you our honest assessment...")
                        .font(.system(size: 16))
                        .lineSpacing(4)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct PitchforkPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Pitchfork header
            HStack {
                Text("PITCHFORK")
                    .font(.system(size: 16, weight: .black))
                    .tracking(2)
                Spacer()
                HStack(spacing: 16) {
                    Text("Reviews")
                    Text("News")
                    Text("Features")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Album art placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 300)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                        }

                    Text(title.replacingOccurrences(of: " - Pitchfork", with: ""))
                        .font(.system(size: 24, weight: .bold))

                    HStack(alignment: .top, spacing: 20) {
                        VStack {
                            Text("8.7")
                                .font(.system(size: 36, weight: .bold))
                            Text("Best New Music")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.red)
                        }
                        .frame(width: 80)

                        Text("A masterful album that pushes boundaries while remaining deeply personal. Each track reveals new layers with repeated listens...")
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct ArchitecturalDigestPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // AD header
            HStack {
                Text("ARCHITECTURAL DIGEST")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                Spacer()
                HStack(spacing: 16) {
                    Text("Homes")
                    Text("Design")
                    Text("Shopping")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Interior photo placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown.opacity(0.1))
                        .aspectRatio(4/3, contentMode: .fit)
                        .overlay {
                            Image(systemName: "building.2")
                                .font(.system(size: 48))
                                .foregroundStyle(.brown.opacity(0.3))
                        }

                    Text(title.replacingOccurrences(of: " - AD", with: ""))
                        .font(.system(size: 24, weight: .bold, design: .serif))

                    Text("By Architecture Editor • Photography by Studio Name")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text("Step inside this remarkable space that seamlessly blends modern design with timeless elegance. The architects have created a dialogue between interior and exterior that transforms how we think about living spaces...")
                        .font(.system(size: 15, design: .serif))
                        .lineSpacing(6)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct DesignWithinReachPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // DWR header
            HStack {
                Text("Design Within Reach")
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                HStack(spacing: 16) {
                    Text("Living")
                    Text("Dining")
                    Text("Lighting")
                    Image(systemName: "bag")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product image placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "chair.lounge")
                                .font(.system(size: 64))
                                .foregroundStyle(.gray.opacity(0.3))
                        }

                    Text(title.replacingOccurrences(of: " - Design Within Reach", with: ""))
                        .font(.system(size: 22, weight: .medium))

                    Text("$4,995.00")
                        .font(.system(size: 18))

                    Text("A timeless piece of modern design that has graced homes and offices worldwide since its introduction. Crafted with premium materials and meticulous attention to detail.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)

                    Button(action: {}) {
                        Text("Add to Cart")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct NikePageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // Nike header
            HStack {
                Image("favicon-nike")
                    .resizable()
                    .frame(width: 40, height: 14)
                Spacer()
                HStack(spacing: 20) {
                    Text("New & Featured")
                    Text("Men")
                    Text("Women")
                    Image(systemName: "bag")
                }
                .font(.system(size: 13))
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "figure.run")
                                .font(.system(size: 64))
                                .foregroundStyle(.orange.opacity(0.3))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Just In")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text(title.replacingOccurrences(of: " - Nike", with: ""))
                            .font(.system(size: 20, weight: .medium))
                        Text("Running Shoes")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("$180")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.top, 4)
                    }

                    Button(action: {}) {
                        Text("Add to Bag")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .cornerRadius(30)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct OnShoesPageView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // On header
            HStack {
                Image("favicon-onshoes")
                    .resizable()
                    .frame(width: 40, height: 16)
                Spacer()
                HStack(spacing: 20) {
                    Text("Men")
                    Text("Women")
                    Text("Accessories")
                    Image(systemName: "bag")
                }
                .font(.system(size: 13))
            }
            .padding()
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "shoe.2")
                                .font(.system(size: 64))
                                .foregroundStyle(.gray.opacity(0.3))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title.replacingOccurrences(of: " - On Running", with: ""))
                            .font(.system(size: 20, weight: .medium))
                        Text("Road Running Shoe")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("$189.99")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.top, 4)
                    }

                    Text("Engineered for performance runners. CloudTec® cushioning meets a responsive Speedboard® for explosive toe-offs.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)

                    Button(action: {}) {
                        Text("Add to Cart")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct GenericPageView: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct DiaLargeLogo: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                // Arch/dome shape
                path.move(to: CGPoint(x: 0, y: height))
                path.addCurve(
                    to: CGPoint(x: width, y: height),
                    control1: CGPoint(x: 0, y: height * 0.1),
                    control2: CGPoint(x: width, y: height * 0.1)
                )
                path.closeSubpath()
            }
            .fill(Color.gray.opacity(0.3))
        }
    }
}

#Preview {
    WebContentsView()
        .frame(width: 800, height: 600)
        .padding()
}
