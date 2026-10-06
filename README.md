# 🎬 CineCut Pro - Mobile Video Editor (Flutter)

[![Build Android APK](https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK/actions/workflows/build-apk.yml/badge.svg)](https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK/actions/workflows/build-apk.yml)
[![Release](https://img.shields.io/github/v/release/robinisking3-byte/CineCut-Pro-Video-Editor-APK?color=amber)](https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK/releases)

A professional video editor built with Flutter, featuring trimming, multi-segment splitting, clip merging, real-time GPU visual filters (Black & White, Sepia, Vintage, Vivid, Cool Cyan, Golden Hour, Film Noir), and CineCut AI Director.

---

## 🚀 Features

### ✂️ Video Trimming
- Interactive dual-handle range slider with millisecond precision
- One-tap shortcuts: "Start at Playhead" and "End at Playhead"
- Instant live duration calculation and preview seeking

### ✂️ Clip Splitting
- Scissor split at the current playhead position
- Boundary safety with edge protection (retains audio & filter configurations across split segments)
- Undo/redo support for split actions

### 🔗 Clip Merging
- **Merge Adjacent**: Seamlessly reunites split segments or joins adjacent clips into a continuous composite
- **Merge All**: Merges all timeline clips into a single unified master sequence

### 🎨 Visual Filters & Color Grading
Real-time GPU matrix color filtering:
- **Black & White (Monochrome)**: Luminance-weighted grayscale
- **Sepia**: Classic warm vintage nostalgic tone
- **Vintage 70s**: Analog cinema film curve
- **Vivid Pop**: Punchy high-saturation color boost
- **Cool Cyan**: Teal sci-fi look
- **Golden Hour**: Sunset amber warmth
- **Film Noir**: High-contrast dramatic B&W
- **Negative Invert**: Inverted color spectrum
- Granular intensity slider (0% to 100%) and project-wide "Apply to All" option

### 📱 Architecture & Workflow
- Multi-track timeline with scrubber playhead and time ruler
- Aspect ratio switcher: 16:9, 9:16 (Reels/Shorts), 1:1, 4:3, 21:9
- Audio ducking & volume controls
- Multi-resolution export engine (720p, 1080p, 4K)

---

## 📦 Download APK

Direct download from GitHub Releases:
👉 **[Download CineCut-Pro-Release.apk](https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK/releases/latest)**

Or from GitHub Actions Artifacts:
👉 **[GitHub Actions Artifacts](https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK/actions)**

---

## 🛠️ Building Locally

```bash
git clone https://github.com/robinisking3-byte/CineCut-Pro-Video-Editor-APK.git
cd CineCut-Pro-Video-Editor-APK
flutter pub get
flutter build apk --release
```
