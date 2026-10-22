# Android APK Build & Installation Guide

This guide describes how to build, sign, and install the **Telugu Voice-Based Tiffin Hotel Debt Management** Android APK.

---

## 1. Prerequisites

1. Install **Flutter SDK** (Version 3.19+ or 3.24+).
2. Install **Android Studio** & **Android SDK Command-line Tools** (API 34+).
3. Connect your Android phone via USB with **USB Debugging** enabled in Developer Options.

---

## 2. Fast Build: Universal Release APK

1. Navigate to the `mobile-app` directory:
   ```bash
   cd "d:/Voice App/mobile-app"
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. Configure your production backend URL in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://your-backend-service.onrender.com/api';
   ```

4. Build the release APK:
   ```bash
   flutter build apk --release
   ```

5. Locate the output APK:
   ```
   mobile-app/build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 3. Optimized Size Build (Split per ABI)

To produce smaller APKs tailored to specific phone architectures (e.g., `arm64-v8a` for modern Android smartphones):

```bash
flutter build apk --split-per-abi
```

Generated files:
- `app-arm64-v8a-release.apk` (~18 MB, recommended for 95% of modern phones)
- `app-armeabi-v7a-release.apk` (~16 MB, for older 32-bit devices)

---

## 4. Installing on Device

### Option A: Via USB / ADB
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Sideloading via WhatsApp or Google Drive
1. Send `app-release.apk` to your phone via Google Drive, WhatsApp, or USB cable.
2. Open the file on the Android device.
3. If prompted, allow "Install from Unknown Sources".
4. Open **Mahima Tiffin Centre (మహిమ టిఫిన్ సెంటర్)** and grant the **Microphone** permission when prompted.
