# NovaCam AI — The Ultimate Free Professional Camera for iPhone

**100% Free | 100% Offline | 100% Privacy-First**

[![Build Status](https://github.com/Kevin99-alt/NovaCam/actions/workflows/build.yml/badge.svg)](https://github.com/Kevin99-alt/NovaCam/actions)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![iOS 18](https://img.shields.io/badge/iOS-18.0-blue)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Dependencies](https://img.shields.io/badge/Dependencies-Zero-brightgreen)

---

## 🎯 What Is NovaCam?

The world's most advanced **100% free**, **fully offline**, **privacy-first** professional camera app for iPhone. DSLR-level manual controls, on-device AI, and professional image processing — **no subscriptions, no ads, no cloud, no tracking, no accounts.**

---

## 🔒 Privacy Promises (All Enforced in Code)

| Promise | How It's Enforced |
|---------|-------------------|
| **No Internet** | `Info.plist` has no network permissions. Zero URLs in source. |
| **No Tracking** | No analytics SDKs. No Firebase. No third-party keys. |
| **No Cloud** | All AI is CoreML + Vision. All processing is CIImage + Metal. |
| **No Accounts** | No login. No registration. No email. |
| **No Ads** | No ad SDKs. No ad placements. |
| **Free Forever** | No IAP. No subscriptions. No paid upgrades. |

---

## 📱 Build & Install

### From Windows (Recommended)

```powershell
# 1. Install Git (https://git-scm.com)
# 2. Clone this repo
git clone https://github.com/Kevin99-alt/NovaCam.git
cd NovaCam

# 3. Push triggers GitHub Actions build (macOS runner, free)
git add .
git commit -m "Build NovaCam"
git push

# 4. Go to: https://github.com/Kevin99-alt/NovaCam/actions
# 5. Download the IPA artifact
# 6. Install with AltStore: https://altstore.io
```

### From macOS

```bash
# Install XcodeGen
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open and run
open NovaCam.xcodeproj
# Select your iPhone → Press Run ▶
```

---

## 🏗️ Architecture

```
NovaCam/
├── App/                     # @main entry + tab navigation
├── Camera/
│   ├── Models/              # 75+ data types (Capture, Editor, Quality)
│   ├── Services/            # AVFoundation + CoreImage pipelines
│   ├── ViewModels/          # MVVM camera + editor logic
│   └── Views/               # Camera, Editor, Overlays, PreviewLayer
├── AI/
│   ├── Models/              # 6 CoreML model wrappers + scene types
│   └── Services/            # On-device AI (Vision + CoreML + heuristics)
├── Core/                    # Protocols, Constants, Extensions
├── Settings/                # 13 persisted UserDefaults settings
└── Resources/               # Info.plist (privacy-first)
```

**Design Pattern:** MVVM + Protocol-Oriented + Dependency Injection  
**Zero External Dependencies:** Only Apple-native frameworks  
**Minimum:** iOS 18.0 | iPhone 11

---

## 🎥 Features (v1.0)

### 📷 Professional Manual Camera
- Manual focus, ISO, shutter speed, white balance, EV compensation
- Focus peaking, zebra exposure, live RGB histogram
- 4 grid types: Rule of Thirds, Golden Ratio, Crosshair, Square
- Horizon level indicator, exposure/focus lock
- RAW (ProRAW), HEIF, JPEG capture

### 🤖 AI Smart Assistant (On-Device)
- 22 scene classifications in real-time (<8ms on ANE)
- Subject detection: faces, eyes, QR codes, barcodes, text
- Lighting analysis: backlit detection, color temperature, brightness
- Smart photography suggestions with severity levels
- Quality scoring: 5 dimensions (sharpness, exposure, composition, noise, color)

### 🎨 Image Enhancement Engine
- Noise reduction, detail recovery, shadow/highlight recovery
- Color enhancement, skin tone correction, dynamic range optimization
- Lens distortion correction, dehaze, clarity, texture enhancement
- 5 enhancement presets: Auto, Portrait, Landscape, Night, Food
- HDR multi-frame merge, Night mode stacking

### 🖌️ Professional Editor
- Light: Exposure, Contrast, Brightness, Highlights, Shadows
- Color: Temperature, Tint, Saturation, Vibrance
- **Curves:** RGB/Red/Green/Blue channels with draggable control points
- **HSL:** 8 color bands with hue shift, saturation, luminance per band
- Detail: Sharpening, Noise Reduction, Clarity, Dehaze
- Effects: Vignette, Grain
- **Healing Brush:** Paint to remove blemishes
- **Clone Stamp:** Source → Target cloning with visual guides
- Undo/Redo, Before/After toggle
- Export: HEIF + JPEG with quality control

### 🎬 Professional Video (Roadmap)
- 4K at 60/30/24 FPS with manual controls
- Live histogram, audio meter, stabilization

---

## 📊 Performance Targets

| Metric | Target |
|--------|--------|
| Camera Launch | <300ms |
| Capture Delay | <50ms |
| Image Processing | <1 second |
| AI Inference | <8ms (ANE) |
| App Size | ~25 MB (with ML models) |
| Dependencies | Zero |

---

## 🚀 CI/CD

Push to `main` → GitHub Actions builds on macOS 15 runner → IPA available as artifact.

Manual TestFlight deploy: trigger workflow with `deploy: true`.

---

Made by [Kevin99-alt](https://github.com/Kevin99-alt) | © 2026 NovaCam
