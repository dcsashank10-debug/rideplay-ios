# Install on your iPhone (Windows, free)

Build the .ipa on GitHub's free macOS runner, then sideload onto your iPhone with AltStore.

## 1. Push to GitHub

```bash
cd RidePlayIOS
git init
git add .
git commit -m "iOS port"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/rideplay-ios.git
git push -u origin main
```

## 2. Wait for the build

Go to your repo → **Actions** tab → click the running workflow. Takes 5-10 min the first time.

When it's green, scroll to the bottom of the run page → **Artifacts** → download `RidePlay-app.zip`.

Inside you'll find:
- `RidePlay-unsigned.ipa` ← this is what you install
- `RidePlay.app` (the raw bundle)
- `rideplay-launch.png` (screenshot from simulator)

## 3. Install AltStore on Windows

1. Download **AltServer** from https://altstore.io
2. Install it (it needs iTunes or Apple Devices app to be installed first — if iTunes isn't there, get it from https://www.apple.com/itunes/ ; for Windows 11 use the Microsoft Store "Apple Devices" app)
3. Open AltServer (it lives in the system tray)
4. Connect your iPhone via USB cable
5. **Trust this computer** on the iPhone when prompted
6. In AltServer tray icon → **Install AltStore** → choose your iPhone
7. Enter your Apple ID email + an **app-specific password** (get one at https://appleid.apple.com → App-Specific Passwords → generate, name it "AltStore")
8. AltStore installs on your iPhone. **Trust the developer profile**: iPhone → Settings → General → VPN & Device Management → tap your Apple ID → Trust

## 4. Side-load RidePlay

1. On iPhone, open **AltStore**
2. Tap **My Apps** tab
3. Tap the **+** in the top-left corner
4. Browse to where you extracted `RidePlay-unsigned.ipa`
5. Pick it → AltStore re-signs with your Apple ID → installs

## 5. Launch

Open **RidePlay** from your home screen. It will work for **7 days**. To re-sign:
- Open AltStore on iPhone → My Apps → tap RidePlay → **Refresh** (must be on the same Wi-Fi as your PC with AltServer running)

## Enable Developer Mode (iOS 16+)

iPhone → Settings → Privacy & Security → **Developer Mode** → toggle on → restart. Required for sideloaded apps to launch.

## If you get stuck

| Error | Fix |
|---|---|
| "App not trusted" | Settings → General → VPN & Device Management → trust your profile |
| "Developer Mode required" | Settings → Privacy & Security → Developer Mode → on |
| "Could not connect to AltServer" | Same Wi-Fi network, AltServer running, USB connected, iTunes/Apple Devices installed |
| "Invalid .ipa" | Make sure you got the file from the GitHub Actions artifact, not a corrupted download |
| App won't open at all | Re-sign via AltStore My Apps → Refresh |

## Why not just pay $99?

- **Free (this path)**: 7-day signing, requires re-signing weekly, limited to 3 sideloaded apps at a time per Apple ID
- **$99/year Apple Developer**: 1-year signing, unlimited apps, can use TestFlight to invite testers, can list on App Store
- **$99 is worth it** if you plan to actually use the app on your phone long-term. Until then, this free path is fine for testing.
