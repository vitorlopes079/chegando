//
//  AlarmSoundService.swift
//  DestinoAlerta
//

import Foundation
import AVFoundation
import AudioToolbox

/// Service to play alarm sounds and ambient rain that work even on silent mode
@MainActor
final class AlarmSoundService: ObservableObject {
    static let shared = AlarmSoundService()

    // MARK: - Published State

    @Published var isRainPlaying: Bool = false
    @Published var isAlarmPlaying: Bool = false

    // MARK: - UserDefaults Keys

    private let rainEnabledKey = "rainSoundEnabled"

    /// User's preference for rain sound (persisted)
    var isRainEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: rainEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: rainEnabledKey) }
    }

    // MARK: - Audio Players

    private var rainPlayer: AVAudioPlayer?
    private var alarmLoopActive = false

    // System sound ID for alarm
    private let alarmSoundID: SystemSoundID = 1005

    // MARK: - Init

    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            // Use .playback category to play sound even when phone is on silent
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Rain Sound

    /// Toggle rain sound on/off
    func toggleRain() {
        if isRainPlaying {
            stopRain()
            isRainEnabled = false
        } else {
            startRain()
            isRainEnabled = true
        }
    }

    /// Start playing rain sound in a loop
    func startRain() {
        // Don't play rain if alarm is active
        guard !isAlarmPlaying else { return }

        guard let url = Bundle.main.url(forResource: "rain-sound", withExtension: "mp3") else {
            print("rain-sound.mp3 not found in bundle")
            return
        }

        do {
            setupAudioSession()

            rainPlayer = try AVAudioPlayer(contentsOf: url)
            rainPlayer?.numberOfLoops = -1 // Loop indefinitely
            rainPlayer?.volume = 0.6 // Ambient volume
            rainPlayer?.prepareToPlay()
            rainPlayer?.play()
            isRainPlaying = true
        } catch {
            print("Failed to play rain sound: \(error)")
        }
    }

    /// Stop rain sound
    func stopRain() {
        rainPlayer?.stop()
        rainPlayer = nil
        isRainPlaying = false
    }

    /// Start rain if user has it enabled (call when alarm is set)
    func startRainIfEnabled() {
        if isRainEnabled && !isAlarmPlaying {
            startRain()
        }
    }

    // MARK: - Alarm Sound

    /// Start playing the alarm sound (stops rain first)
    func startAlarm() {
        // Stop rain immediately when alarm fires
        stopRain()

        guard !isAlarmPlaying else { return }
        isAlarmPlaying = true
        alarmLoopActive = true

        // Reactivate audio session
        setupAudioSession()

        // Start the sound + vibration loop
        playAlarmLoop()
    }

    /// Stop the alarm sound
    func stopAlarm() {
        alarmLoopActive = false
        isAlarmPlaying = false
    }

    private func playAlarmLoop() {
        guard alarmLoopActive else { return }

        // Play system sound with vibration
        AudioServicesPlayAlertSound(alarmSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        // Repeat after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.playAlarmLoop()
        }
    }

    // MARK: - Stop All

    /// Stop all sounds (rain and alarm)
    func stopAll() {
        stopRain()
        stopAlarm()
    }

    // MARK: - Play Single Alert

    /// Play a single alert sound (for notifications when app is in foreground)
    func playAlertOnce() {
        setupAudioSession()
        AudioServicesPlayAlertSound(alarmSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
