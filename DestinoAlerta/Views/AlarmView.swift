//
//  AlarmView.swift
//  DestinoAlerta
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct AlarmView: View {
    let destination: Destination
    let onDismiss: () -> Void
    let onSnooze: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    @State private var isAlarming = true

    // Sound service
    private let soundService = AlarmSoundService.shared

    var body: some View {
        ZStack {
            // Animated background
            Theme.background
                .ignoresSafeArea()

            // Pulsing glow effect
            RadialGradient(
                colors: [
                    Theme.alarm.opacity(glowOpacity * 0.25),
                    Theme.alarm.opacity(glowOpacity * 0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: glowOpacity
            )

            VStack(spacing: 0) {
                Spacer()

                // Alarm rings animation
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Theme.alarm.opacity(0.2 - Double(index) * 0.06), lineWidth: 1.5)
                            .frame(width: 180 + CGFloat(index) * 60)
                            .scaleEffect(pulseScale + CGFloat(index) * 0.1)
                    }

                    // Center icon
                    ZStack {
                        Circle()
                            .fill(Theme.alarm)
                            .frame(width: 120, height: 120)
                            .glow(Theme.alarm, radius: 15)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, options: .repeating)
                    }
                }
                .frame(height: 300)

                // Title
                Text("CHEGANDO!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.alarm)
                    .glow(Theme.alarm, radius: 8)
                    .padding(.top, 20)

                // Destination name
                if !destination.name.isEmpty {
                    Text(destination.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Text("Prepare-se para descer!")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)

                Spacer()

                // Action buttons
                VStack(spacing: 14) {
                    // Dismiss button
                    Button {
                        stopAlarm()
                        onDismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)

                            Text("Dispensar")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Theme.alarm)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .glow(Theme.alarm, radius: 6)
                    }

                    // Snooze button
                    Button {
                        stopAlarm()
                        onSnooze()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")

                            Text("Adiar 2 minutos")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.backgroundSecondary)
                        .foregroundStyle(Theme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.alarm.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimations()
            startAlarm()
        }
        .onDisappear {
            stopAlarm()
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }

    private func startAlarm() {
        isAlarming = true
        // Start playing alarm sound with vibration
        soundService.startAlarm()
    }

    private func stopAlarm() {
        isAlarming = false
        soundService.stopAlarm()
    }
}

#Preview {
    AlarmView(
        destination: Destination(
            name: "Estação Sé",
            latitude: -23.5505,
            longitude: -46.6333
        ),
        onDismiss: {},
        onSnooze: {}
    )
}
