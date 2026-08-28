# Build Status

This project is built automatically on every push via GitHub Actions. The workflow uses a free macOS runner to compile the iOS app and install it on a simulator.

## How to use it

1. Create a new GitHub repo (e.g. `rideplay-ios`)
2. Push this entire folder to it:
   ```bash
   cd RidePlayIOS
   git init
   git add .
   git commit -m "Initial iOS port"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/rideplay-ios.git
   git push -u origin main
   ```
3. Go to the **Actions** tab in your repo
4. Wait for the `Build iOS` workflow to finish (5-10 minutes first time)
5. Download the `RidePlay-app` artifact from the run's summary page
6. Open the `.app` bundle on a Mac with `open RidePlay.app` to test in the local Simulator

## What the workflow does

- Installs Xcode 15.4 (preinstalled on the runner)
- Installs `xcodegen` via Homebrew
- Runs `xcodegen generate` to create the Xcode project
- Builds for iPhone 15 Simulator (no signing required)
- Boots the simulator, installs the app, takes a screenshot
- Uploads the `.app` bundle + screenshot as a downloadable artifact

## Run it on your own Mac instead

```bash
brew install xcodegen
cd RidePlayIOS
xcodegen generate
open RidePlay.xcodeproj
```

Then in Xcode: select your Team, plug your iPhone, ⌘R.
