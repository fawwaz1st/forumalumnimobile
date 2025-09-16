# Forum Alumni Mobile

A modern Flutter mobile application for connecting alumni worldwide with real-time community features, secure authentication, and elegant user experience.

## Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup & Local Development](#setup--local-development)
- [Running the App](#running-the-app)
- [Features](#features)
- [Biometric & Notifications](#biometric--notifications)
- [Troubleshooting](#troubleshooting)
- [Testing & QA](#testing--qa)
- [Performance & Size Optimization](#performance--size-optimization)
- [Contribution Guidelines](#contribution-guidelines)
- [Security & Privacy](#security--privacy)
- [Known Issues & TODO](#known-issues--todo)
- [Contact & Maintainers](#contact--maintainers)
- [License](#license)
- [Quick Commands Cheat Sheet](#quick-commands-cheat-sheet)

## Project Overview

Forum Alumni Mobile is a comprehensive community platform designed for alumni networks. The app enables users to connect, share experiences, participate in discussions, and stay updated with their alma mater community.

**Target Users:**
- Alumni seeking to maintain connections with their academic community
- Educational institutions managing alumni engagement
- Community administrators facilitating alumni interactions

## Tech Stack

**Core Framework:**
- **Flutter**: ^3.22.0 (Dart ^3.9.2)
- **State Management**: hooks_riverpod ^2.5.0
- **Routing**: go_router ^14.0.0

**Key Dependencies:**
- **Networking**: dio ^5.4.0, flutter_dotenv ^5.1.0
- **UI & Fonts**: google_fonts ^6.2.1
- **Security**: flutter_secure_storage ^9.2.0, local_auth ^2.3.0
- **Storage**: hive ^2.2.3, hive_flutter ^1.1.0
- **Real-time**: supabase_flutter ^2.5.6 (optional)
- **Notifications**: flutter_local_notifications ^17.1.2
- **Monitoring**: sentry_flutter ^8.6.0

## Architecture

**Folder Structure:**
```
lib/
├── core/
│   ├── constants/app_config.dart     # Runtime configuration
│   └── theme/app_theme.dart          # Design system
├── features/                         # Feature modules
│   ├── auth/                        # Authentication
│   ├── posts/                       # Posts & feed
│   ├── profile/                     # User profiles
│   ├── settings/                    # App settings
│   └── shared/                      # Shared widgets/utils
├── router/app_router.dart           # Route definitions
├── services/                        # External services
│   └── api/                        # API clients
└── main.dart                        # App entry point
```

**Architecture Patterns:**
- Feature-first modular architecture
- Repository pattern for data layer
- Provider pattern for state management
- Clean separation of concerns

## Prerequisites

**Required:**
- Flutter SDK: 3.22+ (Dart 3.9+)
- Android Studio / VS Code with Flutter extensions
- Android SDK (targetSdk 34) for Android development
- Xcode 15+ for iOS development (macOS only)

**Device Requirements:**
- Android: API level 21+ (Android 5.0+)
- iOS: iOS 12.0+

## Setup & Local Development

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd forumalumnimobile
flutter pub get
```

### 2. Environment Configuration

Create a `.env` file in the project root:

```env
# Environment Configuration
APP_ENV=dev
USE_MOCK=true
API_BASE_URL=https://your-api-server.com/v1
SENTRY_DSN=your-sentry-dsn-here

# SSL Certificate Pinning (optional)
# PINNED_SHA256=sha256/47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=
```

### 3. API Mode Configuration

**Mock Mode (Development - Default):**
```bash
flutter run --dart-define=USE_MOCK=true
```

**Real API Mode (Production):**
```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://your-api.com/v1
```

**Environment Variables:**
- `USE_MOCK`: Toggle between mock and real API (default: `false`)
- `API_BASE_URL`: Backend API endpoint
- `APP_ENV`: Environment (dev/staging/prod)
- `SENTRY_DSN`: Error monitoring (optional)

## Running the App

### Development Commands

**Debug mode:**
```bash
flutter run
```

**Profile mode (performance testing):**
```bash
flutter run --profile
```

**Release mode (device testing):**
```bash
flutter run --release
```

### Build Commands

**Build APK (split per ABI for smaller size):**
```bash
flutter build apk --release --split-per-abi
```

**Build App Bundle (Google Play):**
```bash
flutter build appbundle --release
```

**Build with specific configuration:**
```bash
flutter build apk --release \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://production-api.com/v1 \
  --dart-define=APP_ENV=prod
```

## Features

### Core Features
- **Authentication**: Secure login/register with biometric support
- **Posts & Feed**: Create, view, and interact with community posts
- **Comments**: Real-time commenting system
- **Notifications**: Local push notifications for engagement
- **Profile Management**: User profiles with customizable information
- **Offline Cache**: Local data storage for offline access
- **Search**: Find posts, users, and content
- **Settings**: App preferences and theme management

### Advanced Features
- **Dark/Light Mode**: Automatic theme switching
- **Real-time Updates**: Live feed updates via WebSocket
- **Image Handling**: Photo upload and compression
- **Markdown Support**: Rich text formatting in posts
- **Pull-to-Refresh**: Intuitive feed updates
- **Biometric Login**: Fingerprint/Face ID authentication

## Biometric & Notifications

### Biometric Authentication Setup

**Android Configuration:**
If you encounter `PlatformException(no_fragment_activity, local_auth plugin requires activity to be a FragmentActivity)`:

1. Update `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

2. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Add biometric permissions -->
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
</activity>
```

**iOS Configuration:**
Add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```

### Network Error Workaround

If registration shows "Tidak dapat terhubung ke server" while backend is down:

**Quick Fix:**
```bash
flutter run --dart-define=USE_MOCK=true
```

**Mock Server Setup:**
```bash
# Install json-server globally
npm install -g json-server

# Create db.json
echo '{
  "auth": {
    "login": {
      "access_token": "mock_token",
      "refresh_token": "mock_refresh",
      "expires_at": 1234567890,
      "user": {
        "id": "1",
        "name": "Test User",
        "email": "test@example.com"
      }
    }
  }
}' > db.json

# Run mock server
json-server --watch db.json --port 3000
```

## Troubleshooting

### Common Errors

**1. UnimplementedError: Real API registration not implemented yet**
```
Error: UnimplementedError: Real API registration not implemented yet. set USE_MOCK=true for development
```
**Fix:** Enable mock mode:
```bash
flutter run --dart-define=USE_MOCK=true
```

**2. Biometric PlatformException**
```
PlatformException(no_fragment_activity, local_auth plugin requires activity to be a FragmentActivity)
```
**Fix:** Follow the [Biometric Authentication Setup](#biometric-authentication-setup) instructions above.

**3. Network Connection Error**
```
Error: Tidak dapat terhubung ke server. Periksa jaringan Anda.
```
**Fix:** 
- Check `API_BASE_URL` in `.env`
- Verify device network connection
- For emulator: Check network settings
- Use mock mode: `--dart-define=USE_MOCK=true`

**4. Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub deps --style=compact
flutter build apk --release
```

**5. App Installation Issues**
```bash
# Uninstall previous version
adb uninstall com.example.forumalumnimobile
flutter run
```

## Testing & QA

### Running Tests

**Unit and Widget Tests:**
```bash
flutter test
```

**Test Coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**CI/CD Integration:**
```yaml
# Example GitHub Actions
- name: Run Tests
  run: |
    flutter analyze
    flutter test
```

### Test Requirements
- Unit tests for business logic (repositories, controllers)
- Widget tests for UI components
- Integration tests for critical user flows
- Minimum 80% code coverage for new features

## Performance & Size Optimization

### APK Size Optimization

**Split APK by ABI:**
```bash
flutter build apk --release --split-per-abi
```
*Reduces APK size by ~30-50% by creating separate APKs for different processor architectures.*

**Target Specific Platforms:**
```bash
flutter build apk --release --target-platform=android-arm,android-arm64
```

### Performance Analysis

**Dependency Analysis:**
```bash
flutter pub deps --style=compact
flutter pub remove unused_package
```

**Code Analysis:**
```bash
flutter analyze
```

### Asset Optimization
- Compress images using tools like `flutter_image_compress`
- Remove unused assets from `pubspec.yaml`
- Use vector graphics (SVG) when possible
- Optimize font loading

## Contribution Guidelines

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check code quality
- Format code with `dart format`

### Branch Naming Convention
```
feature/<short-description>    # New features
fix/<issue-description>        # Bug fixes
docs/<doc-update>             # Documentation updates
refactor/<component-name>      # Code refactoring
```

### Commit Message Format
```
type(scope): short description

Longer description explaining the changes...

Closes #issue-number
```

**Types:** feat, fix, docs, style, refactor, test, chore

### Pull Request Requirements
- All tests must pass
- Code coverage should not decrease
- Include relevant documentation updates
- Add unit/widget tests for new features
- Review checklist completed

## Security & Privacy

### API Key Management
**Do NOT commit sensitive data to version control.**

**Using Environment Variables:**
```bash
# .env file (add to .gitignore)
API_SECRET_KEY=your-secret-key
```

**Using dart-define:**
```bash
flutter run --dart-define=API_SECRET_KEY=your-secret-key
```

### Data Protection
- User tokens stored in Flutter Secure Storage
- SSL certificate pinning for API communications
- Input sanitization for user-generated content
- Biometric data processed locally only

## Known Issues & TODO

### Known Issues (Temporary Workarounds)

1. **Biometric PlatformException on Android** *(Assigned to @ozi)*
   - **Issue:** `local_auth plugin requires activity to be a FragmentActivity`
   - **Workaround:** Follow Android configuration steps above
   - **Testing:** Use real device or emulator with biometric simulation enabled

2. **Registration Network Error** *(Backend dependency)*
   - **Issue:** "Tidak dapat terhubung ke server" when backend is unavailable
   - **Workaround:** Use `flutter run --dart-define=USE_MOCK=true`
   - **Testing:** Run local mock server (see Network Error Workaround section)

### TODO for Team
- [ ] Implement comprehensive error logging
- [ ] Add automated UI testing pipeline
- [ ] Optimize image caching strategy
- [ ] Implement offline sync mechanism
- [ ] Add accessibility features (screen reader support)
- [ ] Create automated APK signing pipeline

## Contact & Maintainers

**Primary Maintainers:**
- [@fawwaz](https://github.com/fawwaz) - Lead Developer
- [@ozi](https://github.com/ozi) - Native Platform Integration

**Contributing:**
- Report issues: [GitHub Issues](https://github.com/your-repo/issues)
- Feature requests: [GitHub Discussions](https://github.com/your-repo/discussions)
- Security concerns: security@yourapp.com

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Quick Commands Cheat Sheet

```bash
# Setup
flutter pub get
flutter clean

# Development
flutter run                                    # Debug mode
flutter run --dart-define=USE_MOCK=true       # Mock API mode
flutter run --profile                         # Profile mode
flutter run --release                         # Release mode

# Build
flutter build apk --release --split-per-abi   # Optimized APK
flutter build appbundle --release             # Play Store bundle
flutter build ios --release                   # iOS build

# Analysis & Testing
flutter analyze                               # Code analysis
flutter test                                  # Run tests
flutter test --coverage                       # Test coverage

# Maintenance
flutter doctor                                # Check setup
flutter upgrade                               # Update Flutter
flutter pub upgrade                           # Update dependencies
```

---

**Happy Coding! 🚀**

*Built with ❤️ using Flutter*
