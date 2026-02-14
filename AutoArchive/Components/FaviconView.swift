//
//  FaviconView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct FaviconView: View {
    let favicon: TabItem.FaviconType
    var size: CGFloat = 16

    var body: some View {
        Group {
            switch favicon {
            case .systemSymbol(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.875))
                    .foregroundStyle(.secondary)
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            case .dia:
                Image("favicon-dia")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            // Asset-based favicons
            case .google:
                Image("favicon-google")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .youtube:
                Image("favicon-youtube")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .wikipedia:
                Image("favicon-wikipedia")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .reddit:
                Image("favicon-reddit")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .pitchfork:
                Image("favicon-pitchfork")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .verge:
                Image("favicon-verge")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .architecturalDigest:
                Image("favicon-architecturaldesign")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .designWithinReach:
                Image("favicon-designwithinreach")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .polygon:
                Image("favicon-polygon")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .nyt:
                Image("favicon-nyt")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .onShoes:
                Image("favicon-onshoes")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            case .nike:
                Image("favicon-nike")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct DiaLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Simple arch/dome shape
        path.move(to: CGPoint(x: 0, y: height))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height),
            control: CGPoint(x: width / 2, y: -height * 0.3)
        )
        path.closeSubpath()

        return path
    }
}

#Preview {
    VStack(spacing: 10) {
        HStack(spacing: 20) {
            FaviconView(favicon: .dia)
            FaviconView(favicon: .google)
            FaviconView(favicon: .youtube)
            FaviconView(favicon: .wikipedia)
            FaviconView(favicon: .reddit)
            FaviconView(favicon: .nyt)
        }
        HStack(spacing: 20) {
            FaviconView(favicon: .verge)
            FaviconView(favicon: .polygon)
            FaviconView(favicon: .pitchfork)
            FaviconView(favicon: .architecturalDigest)
            FaviconView(favicon: .designWithinReach)
            FaviconView(favicon: .nike)
            FaviconView(favicon: .onShoes)
        }
    }
    .padding()
}
