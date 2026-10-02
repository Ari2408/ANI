#!/bin/bash
set -e

echo "================================================================="
echo "  Purb Chetana - Android APK Build (AGP 8.11.1 & Flutter 3.47)"
echo "================================================================="

# 1. Setup Java 17
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# 2. Setup Android SDK Directory
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=/snap/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$PATH

# 3. Clean local build artifacts
echo "🧹 Cleaning build cache..."
flutter clean || true

# 4. Fetch updated dependencies
echo "📦 Resolving Flutter dependencies..."
flutter pub get

# 5. Build Release APK with AGP bypass flag
echo "🚀 Building Release APK..."
flutter build apk --release --android-skip-build-dependency-validation

# 6. Copy build artifact to root directory
cp build/app/outputs/flutter-apk/app-release.apk PurbChetana-v1.0-release.apk

echo "================================================================="
echo "  🎉 SUCCESS! Release APK built cleanly at:"
echo "  $(pwd)/PurbChetana-v1.0-release.apk"
echo "================================================================="

