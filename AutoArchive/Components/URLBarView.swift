//
//  URLBarView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct URLBarView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Navigation Actions
            HStack(spacing: 17) {
                // Back button (active)
                Text("􀯶")
                    .font(.system(size: 12.565, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))

                // Forward button (inactive)
                Text("􀯻")
                    .font(.system(size: 12.565, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.25))

                // Refresh button
                Text("􀅈")
                    .font(.system(size: 12.565, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
            }

            Spacer()

            // URL Container (empty in this state)

            Spacer()

            // Chat Button
            HStack(spacing: 5) {
                Image(systemName: "message.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("Chat")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .frame(height: 42)
    }
}

struct PersonalizationIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            Path { path in
                // Simple person/user silhouette shape
                let centerX = size / 2
                let headRadius = size * 0.2

                // Head
                path.addEllipse(in: CGRect(
                    x: centerX - headRadius,
                    y: size * 0.15,
                    width: headRadius * 2,
                    height: headRadius * 2
                ))

                // Body/shoulders
                path.move(to: CGPoint(x: size * 0.15, y: size * 0.9))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.85, y: size * 0.9),
                    control: CGPoint(x: centerX, y: size * 0.45)
                )
            }
            .fill(Color.black)
        }
    }
}

#Preview {
    URLBarView()
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
}
