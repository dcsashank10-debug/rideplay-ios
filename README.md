# RidePlay iOS

Native iOS port of the RidePlay Android app. SwiftUI + AVFoundation, music via YouTube (Invidious) + Audius + local library.

## Build

This project is set up for [XcodeGen](https://github.com/yonaskolb/XcodeGen). On a Mac:

```bash
brew install xcodegen
cd RidePlayIOS
xcodegen generate
open RidePlay.xcodeproj
```

Then in Xcode:
1. Select the `RidePlay` target → Signing & Capabilities
2. Pick your Team (you need a paid Apple Developer account for CarPlay)
3. Plug in your iPhone, set it as the run destination, hit ⌘R

## What's wired

| Feature | Implementation |
|---|---|
| Streaming audio | `AVPlayer` + `AVPlayerItem`, background `AVAudioSession` |
| YouTube | `YouTubeMusicSource` → Invidious API (7-instance failover) |
| Audius | `AudiusMusicSource` → audius.co |
| Local music | `LocalMusicSource` → `MPMediaQuery` |
| Search | 300ms debounce, fan out to all sources, resolve YouTube stream on tap |
| Now Playing | `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter` (lock screen, control center) |
| Background audio | `UIBackgroundModes: audio` |
| Bluetooth / AirPlay | `.allowAirPlay`, `.allowBluetoothA2DP` audio session |
| CarPlay | `CarPlaySceneDelegate` with YouTube + Audius tabs |
| Pre-buffer | `AVURLAsset.loadValuesAsynchronously` for next track |
| Now Playing UI | Drag-to-seek slider, 15s back / 30s fwd, mini player + full screen |

## CarPlay setup

CarPlay requires the **`com.apple.developer.carplay-audio`** entitlement. Apple issues this only to apps that pass their CarPlay audio review.

To enable:
1. Apply at https://developer.apple.com/contact/carplay/
2. Once approved, the entitlement is added to your Apple Developer account
3. In Xcode, sign in with that team and the CarPlay capability will be available
4. Test on a real CarPlay head unit or simulator (Xcode → Window → Devices and Simulators → CarPlay)

Without the entitlement, the app still works fine on iPhone — the CarPlay scene just won't activate.

## Known limitations vs Android version

- No equalizer/audio effects (iOS system handles audio quality, no equivalent to Media3 offload)
- No shuffle/repeat controls exposed in UI yet (can be added via `AVPlayerItem` actions)
- Trending for YouTube uses query terms (no real "music trending" endpoint on Invidious)
- No Coil-equivalent image cache; uses SwiftUI's built-in `AsyncImage` (sufficient for our throughput)

## File map

```
RidePlay/
├── App/                    SwiftUI entry, scenes, Info.plist
├── Models/                 Track, Album, Artist, Playlist, MediaItem
├── Data/
│   ├── MusicRepository.swift
│   └── Source/             YouTube, Audius, Local
├── Networking/             APIClient (URLSession)
├── Audio/                  AudioPlayer (AVPlayer), NowPlayingState
├── Views/                  Home, Search, Library, NowPlaying, MiniPlayer
├── CarPlay/                CarPlay scene delegate
└── Assets.xcassets/        App icon, accent color
```
