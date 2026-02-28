//
//  Theme.swift
//  DestinoAlerta
//

import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "0D0D0D")
    static let backgroundSecondary = Color(hex: "1A1A1A")
    static let backgroundTertiary = Color(hex: "262626")

    static let accent = Color(hex: "00E5FF") // Cyan
    static let accentDim = Color(hex: "00E5FF").opacity(0.3)

    static let alarm = Color(hex: "FF3D71") // Neon pink
    static let alarmDim = Color(hex: "FF3D71").opacity(0.3)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - App Info
    static let appName = "Chegando!"
    static let tagline = "Chega no destino, mesmo dormindo"
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Radar Animation View

struct RadarPulseView: View {
    @State private var pulse1 = false
    @State private var pulse2 = false
    @State private var pulse3 = false

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .stroke(Theme.accent.opacity(0.15), lineWidth: 1.5)
                .scaleEffect(pulse1 ? 2.5 : 0.8)
                .opacity(pulse1 ? 0 : 0.6)

            // Middle pulse
            Circle()
                .stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
                .scaleEffect(pulse2 ? 2.0 : 0.8)
                .opacity(pulse2 ? 0 : 0.6)

            // Inner pulse
            Circle()
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1.5)
                .scaleEffect(pulse3 ? 1.5 : 0.8)
                .opacity(pulse3 ? 0 : 0.6)

            // Center dot
            Circle()
                .fill(Theme.accent)
                .frame(width: 10, height: 10)
                .shadow(color: Theme.accent.opacity(0.4), radius: 6)
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                pulse1 = true
            }
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false).delay(0.4)) {
                pulse2 = true
            }
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false).delay(0.8)) {
                pulse3 = true
            }
        }
    }
}

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius / 2)
            .shadow(color: color.opacity(0.2), radius: radius)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RadarPulseView()
    }
}
