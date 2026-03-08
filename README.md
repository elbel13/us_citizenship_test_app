# US Citizenship Test App

An app to help users prepare for the US Citizenship Test with flashcards, multiple choice questions, writing practice, reading practice, and simulated interviews.

After helping my wife study for her citizenship test, I realized the stresful and high stakes this test can be for immigrants. Many don't have access to good study materials or structured practice. This app aims to fill that gap by providing a free, easy-to-use, comprehensive study tool.

## Features
- Flashcards
- Multiple Choice Questions
- Writing Practice
- Reading Practice
- Simulated Interviews
- Test Readiness Assessment

## Local Development

### Prerequisites

- Flutter 3.41.4 (installed to `~/development/flutter`)
- Android SDK (installed to `~/Android/Sdk`)
- Java 21 (`java-21-openjdk-devel`)
- Emulator AVD: `Pixel_9_API_35`

Ensure these are in your `~/.bashrc` (already configured if you followed the setup):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
```

### Running the App

**1. Start the emulator** (in a separate terminal):

```bash
emulator -avd Pixel_9_API_35
```

> **Note:** For hardware-accelerated emulation (faster), log out and back in after initial setup so your `kvm` group membership takes effect.

**2. Wait for the emulator to finish booting**, then in another terminal:

```bash
cd ~/Repos/us_citizenship_test_app
flutter run
```

Flutter will detect the running emulator automatically and deploy the debug build to it.

**Other useful commands:**

```bash
# List available emulators and connected devices
flutter devices

# Run on a specific device if multiple are connected
flutter run -d <device-id>

# Hot reload while running: press r in the terminal
# Hot restart:             press R in the terminal
# Quit:                    press q in the terminal

# Build a debug APK without launching
flutter build apk --debug

# Run all tests
flutter test
```
