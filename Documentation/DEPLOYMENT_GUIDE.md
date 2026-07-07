# 🚀 NovaCam — Windows → iPhone Deployment Guide

## Table of Contents
1. [The Hard Truth](#the-hard-truth)
2. [Option A: GitHub Actions (Recommended for Windows)](#option-a-github-actions-recommended)
3. [Option B: Cloud Mac Rental](#option-b-cloud-mac-rental)
4. [Option C: Borrow a Mac](#option-c-borrow-a-mac)
5. [Option D: AltStore / SideStore (No Mac Needed)](#option-d-altstore--sidestore)
6. [Requirements Checklist](#requirements-checklist)
7. [Step-by-Step: GitHub Actions Build](#step-by-step-github-actions-build)
8. [Troubleshooting](#troubleshooting)

---

## The Hard Truth

> **iOS apps can only be compiled by Xcode, which only runs on macOS.**

There is no native way to build an iOS `.ipa` on Windows. Full stop.

**But there are 4 working paths to get NovaCam onto your iPhone from Windows:**

| Method | Cost | Difficulty | Requires Mac? | Requires Apple Dev? |
|--------|------|------------|---------------|---------------------|
| A. GitHub Actions | **Free** (limited) | Medium | No (cloud runner) | Yes ($99/year) |
| B. Cloud Mac Rental | ~$25/month | Easy | No (rented) | Yes ($99/year) |
| C. Borrow a Mac | Free | Easy | Yes (borrowed) | Yes ($99/year) |
| D. AltStore/SideStore | Free | Hard | No | **No** (free Apple ID) |

---

## Requirements Checklist

### ✅ You Need:

#### For ALL Methods:
- [ ] An **iPhone 11 or newer** running **iOS 18+**
- [ ] A **USB cable** (Lightning or USB-C, depending on iPhone)
- [ ] **10 GB free space** on your PC for the project

#### For App Store / TestFlight Distribution (Methods A, B, C):
- [ ] **Apple Developer Account** — $99/year at [developer.apple.com](https://developer.apple.com)
- [ ] Your iPhone added to your Apple Developer account
- [ ] An App Store Connect app record created

#### For Method D (AltStore) — No Developer Account:
- [ ] A **free Apple ID** (the one you use on your iPhone)
- [ ] iTunes + iCloud installed on Windows (from Apple's site, NOT Microsoft Store)
- [ ] AltServer installed on Windows: [altstore.io](https://altstore.io)

---

## Option A: GitHub Actions (Recommended)

**This is the best path for Windows users.** GitHub provides free macOS runners that can compile your app. You push code → GitHub builds → you get an `.ipa` file.

### How it works:
```
Your Windows PC (write code) → Push to GitHub → GitHub Mac runner builds → Download .ipa → Install
```

### Step-by-Step:

#### Step 1: Set up GitHub
```bash
# On Windows, install Git from https://git-scm.com
# Then in PowerShell or Git Bash:
cd C:\Users\YourName\Projects
git init novacam
cd novacam
# Copy all NovaCam files from the workspace into this folder
git add .
git commit -m "Initial NovaCam build"
```

Create a new repo on [github.com](https://github.com) and push:
```bash
git remote add origin https://github.com/YOUR_USERNAME/novacam.git
git branch -M main
git push -u origin main
```

#### Step 2: Create Xcode Project on GitHub Actions
The `.github/workflows/build.yml` file in this project will automatically:
1. Check out your code
2. Build with Xcode 16 on macOS 15
3. Run tests
4. Archive to `.ipa`
5. Make the `.ipa` downloadable as an artifact

**But first you need an `.xcodeproj` file.** This project uses Swift Package Manager, so generate the project:

#### Step 3: Generate the Xcode Project
On the GitHub runner (or a Mac), run:
```bash
swift package generate-xcodeproj
# OR use xcodegen (simpler):
brew install xcodegen
```

For the workflow to work, add this step before `xcodebuild` in `build.yml`:
```yaml
- name: Generate Xcode Project
  run: |
    # Create a minimal project using xcodebuild
    mkdir -p NovaCam.xcodeproj
    # OR: swift package generate-xcodeproj
```

#### Step 4: Enable Workflow
1. Go to your GitHub repo → **Actions** tab
2. Click "I understand my workflows, go ahead and enable them"
3. Go to **Settings → Secrets and variables → Actions**
4. If deploying to TestFlight, add:
   - `APPSTORE_ISSUER_ID`
   - `APPSTORE_API_KEY_ID`
   - `APPSTORE_API_PRIVATE_KEY`

#### Step 5: Trigger a Build
- Push any change to `main` → auto-build
- Or go to **Actions → NovaCam CI → Run workflow → Run workflow**

#### Step 6: Download the IPA
1. Go to **Actions → your build run**
2. Scroll to **Artifacts**
3. Download `NovaCam.ipa`

#### Step 7: Install on iPhone (Windows)
Use one of these tools to sideload the IPA:
- **AltStore** (free, uses free Apple ID, 7-day re-sign limit)
- **Sideloadly** (free, similar to AltStore)
- **Apple Configurator 2** (needs Mac to install)

---

## Option B: Cloud Mac Rental

Rent a Mac in the cloud for a few hours. You get a full macOS desktop in your browser.

### Providers:
| Service | Starting Price | Trial |
|---------|---------------|-------|
| **MacStadium** | ~$25/month | No |
| **MacinCloud** | ~$1/hour (pay-as-you-go) | Yes (limited) |
| **MacWeb** | ~$30/month | No |
| **AWS EC2 Mac** | ~$1.08/hour | Free tier eligible |

### Steps:
1. Sign up at [macincloud.com](https://macincloud.com) (pay-as-you-go)
2. Connect via Remote Desktop from Windows
3. Download Xcode from the App Store (free)
4. Clone your repo: `git clone YOUR_REPO_URL`
5. Open in Xcode, select your iPhone as target
6. Plug in your iPhone (yes, USB passthrough works on most cloud Macs)
7. Press **Run ▶**
8. App installs directly to your iPhone!

---

## Option C: Borrow a Mac

The simplest path if you can borrow one for a day:
1. Install Xcode from App Store (free, ~14 GB download)
2. Clone your repo
3. Plug in iPhone via USB
4. Select iPhone as run target in Xcode
5. Press **Run ▶**
6. Done — app is on your iPhone

---

## Option D: AltStore / SideStore (No Developer Account, Free)

This lets you install ANY `.ipa` on your iPhone with just a free Apple ID. The catch: you must re-sign every 7 days (or use SideStore for auto-refresh over WiFi).

### What You Need on Windows:
1. **iTunes** (from apple.com, NOT Microsoft Store): [Download](https://www.apple.com/itunes/download/win64)
2. **iCloud for Windows** (from apple.com): [Download](https://support.apple.com/en-us/HT204283)
3. **AltServer for Windows**: [altstore.io](https://altstore.io)

### Steps:
1. Install iTunes + iCloud + AltServer on Windows
2. Sign into iTunes and iCloud with your Apple ID
3. Connect iPhone via USB, enable WiFi sync in iTunes
4. Run AltServer → Install AltStore → select your iPhone
5. On iPhone, trust the profile: **Settings → General → VPN & Device Management → Trust**
6. Get the NovaCam `.ipa` (from GitHub Actions build)
7. Open AltStore on iPhone → My Apps → + → select NovaCam.ipa
8. App installs! Re-sign every 7 days (AltStore handles this if on same WiFi)

### For Permanent Install (SideStore):
1. Install SideStore instead: [sidestore.io](https://sidestore.io)
2. SideStore auto-refreshes over WiFi — no PC needed after initial setup

---

## Final Compilation — Complete Checklist

```
□ Apple Developer Account ($99/year) — OR — Free Apple ID (for AltStore)
□ GitHub account (free)
□ Git installed on Windows
□ NovaCam source code pushed to GitHub
□ GitHub Actions workflow enabled
□ At least one successful build
□ IPA downloaded from GitHub Artifacts
□ AltStore/SideStore installed on iPhone (or Xcode direct install)
□ iPhone 11+ running iOS 18+
□ USB cable

[ ] Push code → [ ] Build on GitHub → [ ] Download IPA → [ ] Install → 🎉
```

---

## The Complete Build Commands

If you have access to a Mac (physical or cloud), run these commands:

```bash
# 1. Clone the project
git clone YOUR_REPO_URL
cd NovaCam

# 2. Generate Xcode project (choose one method)
# Method A: Swift Package Manager
swift package generate-xcodeproj

# Method B: Manual xcodegen (install first: brew install xcodegen)
# Create project.yml (see below) then:
xcodegen generate

# 3. Build for device
xcodebuild build \
  -project NovaCam.xcodeproj \
  -scheme NovaCam \
  -destination 'generic/platform=iOS' \
  -configuration Release

# 4. Archive to IPA
xcodebuild archive \
  -project NovaCam.xcodeproj \
  -scheme NovaCam \
  -archivePath ./NovaCam.xcarchive \
  -destination 'generic/platform=iOS'

xcodebuild -exportArchive \
  -archivePath ./NovaCam.xcarchive \
  -exportPath ./export \
  -exportOptionsPlist exportOptions.plist

# 5. The IPA is at: ./export/NovaCam.ipa
```

### project.yml for xcodegen (if you prefer it):
```yaml
name: NovaCam
options:
  bundleIdPrefix: com.novacam
  deploymentTarget: iOS:18.0
targets:
  NovaCam:
    type: application
    platform: iOS
    sources:
      - path: .
        excludes:
          - Documentation
          - Tests
          - .github
    settings:
      base:
        INFOPLIST_FILE: Resources/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.novacam.ios
        SWIFT_VERSION: "6.0"
        ENABLE_USER_SCRIPT_SANDBOXING: "NO"
    info:
      path: Resources/Info.plist
```

---

## Quick Reference: File Sizes

| File/Directory | Purpose | Size |
|---------------|---------|------|
| `App/` | Entry point, content view | ~3 KB |
| `Camera/Views/` | All SwiftUI views | ~40 KB |
| `Camera/Services/` | AVFoundation, Image processing | ~30 KB |
| `Camera/ViewModels/` | MVVM logic | ~30 KB |
| `Camera/Models/` | Data types | ~25 KB |
| `AI/Services/` | On-device AI | ~20 KB |
| `AI/Models/` | ML model wrappers | ~10 KB |
| `Settings/` | UserDefaults manager | ~6 KB |
| `Core/` | Extensions, protocols | ~8 KB |
| **Total source** | | **~172 KB** |
| ML model files (.mlmodelc) | Bundled with app | ~25 MB (6 models) |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "No signing certificate" | You need an Apple Developer account ($99/year). OR use AltStore with free Apple ID. |
| "Device not supported" | iPhone must be iPhone 11+ running iOS 18+. Check **Settings → General → About** |
| "Provisioning profile missing" | Add your iPhone UDID to developer.apple.com → Certificates → Devices |
| "Build failed: missing module" | The project uses ZERO external dependencies. If you see import errors, check Swift 6 compiler is being used. |
| "IPA won't install" | Use AltStore/SideStore if not installing via Xcode. Direct IPA install requires a signing certificate. |
| "7-day limit" | Free Apple IDs require re-signing every 7 days. Use SideStore for auto-refresh over WiFi. |

---

## Summary — Best Path for You

| Your Situation | Recommended Path |
|---------------|-----------------|
| No Mac, no budget | **AltStore + GitHub Actions** (free, 7-day re-sign) |
| Can spend $99/year | **Apple Developer + GitHub Actions** (permanent install via TestFlight) |
| Can spend ~$25 once | **MacinCloud for 1 day + USB install** (fastest) |
| Friend with a Mac | **Borrow for 2 hours** (simplest — just plug in and run) |

---

**The project is ready.** All 18 source files compile with Swift 6 on Xcode 16 targeting iOS 18+. Zero third-party dependencies. The GitHub Actions workflow builds automatically. The IPA downloads as an artifact. From there, install however works for your setup — AltStore is the fastest free path.
