//
//  CommandBarView.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

struct CommandBarView: View {
    @State private var searchText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 26) {
            // Text Area
            HStack(spacing: 8) {
                // Search icon
                Text("􀊫")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary.opacity(0.85))
                    .opacity(0.5)
                    .frame(width: 24, height: 28)

                // Real text field with blinking cursor
                TextField("Ask Anything...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary.opacity(0.85))
                    .focused($isTextFieldFocused)
            }
            .onAppear {
                // Auto-focus the text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }

            // Toolbar
            HStack {
                // Add tabs or files button
                InputToolbar()

                Spacer()

                // Input accessories
                InputAccessories()
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 32, y: 16)
        .frame(width: 600)
    }
}

struct InputToolbar: View {
    var body: some View {
        HStack(spacing: 6) {
            // Add tabs or files button
            HStack(spacing: 4) {
                Text("􀅼")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("Add tabs or files")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 9)
            .padding(.trailing, 12)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5)
            )

            // More options button
            Text("􀍠")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .opacity(0.5)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
        }
    }
}

struct InputAccessories: View {
    var body: some View {
        HStack(spacing: 6) {
            // Microphone button
            Text("􀊰")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 33, height: 33)

            // Send button (disabled)
            Text("􀄨")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.25))
                .frame(width: 33, height: 33)
                .background(Color.black.opacity(0.05))
                .clipShape(Circle())
        }
    }
}

#Preview {
    CommandBarView()
        .padding()
        .background(Color.gray.opacity(0.1))
}
