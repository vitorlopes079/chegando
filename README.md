# Chegando!

**Chega no destino, mesmo dormindo.**

A smart arrival alert iOS app that monitors your location and wakes you up when you're approaching your destination. Perfect for commuters who want to rest during bus or train rides without missing their stop.

## Features

- **Interactive Map Picker** - Tap on the map or search for addresses to set your destination
- **Configurable Alert Radius** - Choose from 300m, 500m, 750m, or 1km trigger zones
- **Background Monitoring** - Works even when the app is closed or phone is locked
- **Smart Notifications** - Alerts pierce through Focus Mode using time-sensitive notifications
- **Persistent Alarm** - Looping alarm with vibration that works even on silent mode
- **Live Tracking** - Real-time distance display with map visualization
- **Ambient Rain Sound** - Optional relaxing rain sound while you wait
- **Snooze Option** - 2-minute snooze if you need a bit more time

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Permissions

The app requires the following permissions:

| Permission | Purpose |
|------------|---------|
| Location (Always) | Monitor your position in the background to trigger alerts |
| Notifications | Send alarm notifications when you arrive |

## Architecture

The app follows the **MVVM** pattern with a clean service layer:

```
DestinoAlerta/
├── DestinoAlertaApp.swift      # App entry point
├── Theme.swift                  # Design system
├── rain-sound.mp3              # Ambient audio
│
├── Models/
│   └── Destination.swift        # Core data model
│
├── Services/
│   ├── LocationService.swift    # CoreLocation wrapper
│   ├── GeofenceService.swift    # Region monitoring
│   ├── NotificationService.swift # Push notifications
│   └── AlarmSoundService.swift  # Audio playback
│
├── ViewModels/
│   ├── MapViewModel.swift       # Map picker logic
│   └── TrackingViewModel.swift  # Live tracking
│
└── Views/
    ├── HomeView.swift           # Main screen
    ├── MapPickerView.swift      # Destination selection
    ├── LiveTrackingView.swift   # Real-time tracking
    └── AlarmView.swift          # Alarm alert
```

## Frameworks Used

| Framework | Purpose |
|-----------|---------|
| SwiftUI | UI and state management |
| MapKit | Maps and location search |
| CoreLocation | GPS and geofencing |
| UserNotifications | Push notifications |
| AVFoundation | Audio playback |
| AudioToolbox | System sounds and vibration |
| Combine | Reactive data binding |

## How It Works

1. **Set Destination** - Open the map and tap on your destination or search for an address
2. **Choose Radius** - Select how close you want to be before the alarm triggers
3. **Confirm** - The app starts monitoring your location in the background
4. **Relax** - Optionally enable rain sounds and rest during your journey
5. **Get Alerted** - When you enter the geofence radius, you'll receive a notification and alarm

## Design

The app features a dark cyberpunk aesthetic with:

- Dark backgrounds (`#0D0D0D`, `#1A1A1A`, `#262626`)
- Cyan accent color (`#00E5FF`) for primary elements
- Neon pink (`#FF3D71`) for alarm states
- Subtle glow effects on interactive elements
- Animated radar pulse when monitoring

## Building

1. Clone the repository
2. Open `DestinoAlerta.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on a physical device (location features require a real device)

## License

*Add your license here*

## Author

Vitor Lopes
