# CoreX Messenger

Global Connections. Seamless Communications.

## Release Toolchain

- Flutter 3.24.x
- Dart 3.5.x
- Java 17
- Android SDK 36 (compile), API 35 (target)
- Gradle 8.7
- Android Gradle Plugin 8.6.0
- Kotlin 2.2.20
- NDK 26.1
- iOS 14 or newer

## Setup

```sh
flutter pub get
flutter analyze
flutter test
```

Create Android release artifacts with:

```sh
flutter build appbundle --release
```

Create an iOS archive with:

```sh
flutter build ipa --release
```

Release signing files and store credentials must remain outside Git.
