# Installation & Viewing Guide for SmritiJyoti Mobile Platform

You can view, run, and test **SmritiJyoti** in two easy ways:

---

## Method 1: Instant Browser / Mobile Preview (Fastest - No Setup Required)

The project includes an instant mobile web app layout with PWA support that runs directly in any browser:

1. **Start the Local Web Server**:
   Open terminal and run:
   ```bash
   cd /home/dinakar3108/Downloads/PR1
   python3 -m http.server 8080
   ```

2. **Open in Browser**:
   - Go to: `http://localhost:8080`
   - Press **F12** (Developer Tools) -> Press **Ctrl + Shift + M** (Device Toolbar) to simulate an **Android / iPhone screen**.

3. **Test Features**:
   - Switch languages between **Tamil (தமிழ்)**, Assamese, Bengali, Manipuri, Mizo, Khasi, Nagamese, and English.
   - Play the 4 cognitive games (Visual Memory Match, Routine Sequencing, Loom Pattern Sorting, Mindful Nature).
   - Test Medicine Reminders & Water Intake Gauge.
   - Access Caregiver Dashboard using PIN `1234`.

---

## Method 2: Native Flutter / Dart Mobile App (Android & iOS)

To build and run the native Flutter application on an Android device, emulator, or desktop:

### 1. Install Flutter SDK (If not already installed)
Follow official instructions at [flutter.dev](https://docs.flutter.dev/get-started/install) or install via terminal:
```bash
sudo snap install flutter --classic
flutter doctor
```

### 2. Fetch Project Dependencies
Navigate to the project root and get packages:
```bash
cd /home/dinakar3108/Downloads/PR1
flutter pub get
```

### 3. Run the App
- **Run on Web / Chrome**:
  ```bash
  flutter run -d chrome
  ```
- **Run on Connected Android Phone or Emulator**:
  ```bash
  flutter run -d android
  ```
- **Run on Desktop (Linux / Mac / Windows)**:
  ```bash
  flutter run -d linux
  ```

### 4. Build APK for Android Phone Installation
To generate an `.apk` file to send and install directly on any Android smartphone:
```bash
flutter build apk --release
```
The output file will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
