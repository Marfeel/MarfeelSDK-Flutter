# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter plugin (`marfeel_sdk`) that bridges the native Marfeel Compass analytics SDK for iOS and Android. It provides Dart APIs for page/screen tracking, multimedia (video/audio) tracking, scroll tracking, conversion events, user segmentation, and consent management.

## Common Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/compass_tracking_test.dart

# Analyze/lint
flutter analyze

# Run the example app
cd example && flutter run
```

## Architecture

The plugin uses Flutter's **MethodChannel** (`com.marfeel.sdk/compass`) for Dart-to-native communication.

### Dart layer (`lib/`)
- `marfeel_sdk.dart` — barrel export file
- `src/compass_tracking.dart` — main tracking API (static methods: initialize, trackNewPage, trackScreen, stopTracking, user/session/page vars, conversions, consent, segments, `getUserSegments`/`getUserVars` merged reads, `resetUser` sign-out)
- `src/multimedia_tracking.dart` — video/audio tracking (initializeItem, registerEvent)
- `src/compass_scroll_view.dart` — widget wrapping `SingleChildScrollView` that automatically reports scroll percentage via `CompassTracking.updateScrollPercentage`
- `src/types.dart` — enums and data classes (UserType, ConversionScope, MultimediaType, MultimediaEvent, ConversionOptions, MultimediaMetadata, RFV)
- `src/cdp/cdp.dart` — `Cdp` facade: identity (`setIdentity`/`deleteIdentity`/`getUserProfile`/`getMasterId`, hashing helpers, `CdpIdentityTypes`), publisher consents (`trackConsent`/`getConsent`/`hasConsent`), device-owned segments (`addCdpSegment`/`setCdpSegments`/…), Server Segments / Properties, and meters. Identity is gated by `initialize(enableCdp: true)` + CMP consent on the native side; publisher consents only by `enableCdp`. All calls are async over the channel. Old flat names (`cdpDoIdentityLink`, `getCdpData`, `getCdpMasterId`) stay as deprecated delegates — the public surface is add-only (`test/cdp_public_surface_test.dart`).
- `src/cdp/models.dart` — CDP data classes (CdpData, CdpRfv, CdpIdentityTypes, CdpConsent*, MeterState, MeterWindow, MeterNotFoundError). The CDP logic lives in the native SDKs; Dart only carries these values. `CompassTracking.resetUser` / `getUserSegments` / `getUserVars` live in `compass_tracking.dart`.
- `src/method_channel.dart` — shared `MethodChannel` constant

### Native layers
- **Android** (`android/src/.../MarfeelSdkPlugin.kt`) — Kotlin plugin implementing `FlutterPlugin`, `MethodCallHandler`, `ActivityAware`. Dispatches all method channel calls to native `CompassTracking`/`MultimediaTracking` on the main thread via `Handler(Looper.getMainLooper())`.
- **iOS** (`ios/Classes/MarfeelSdkPlugin.swift`) — Swift plugin mapping method channel calls to `CompassTracker`/`CompassTrackerMultimedia`.

### Native SDK dependencies
- Android: `com.marfeel.compass:views:1.18.3` (from `https://repositories.mrf.io/nexus/repository/mvn-marfeel-public/`)
- iOS: `MarfeelSDK-iOS ~> 2.18.14` (CocoaPods)

Both plugins call native methods only present in the native SDKs' CDP branches (`setIdentity`, `trackConsent`, `resetUser`, `getServerSegments`, …); bump the two versions above once those releases are published. To compile the plugins against a local checkout, point `android/build.gradle` at the SDK's AAR (`implementation files(...)` plus its POM dependencies) and add `pod 'MarfeelSDK-iOS', :path => ...` to `example/ios/Podfile`, then revert.

## Testing

Tests use `flutter_test` with mock method channel handlers (`TestDefaultBinaryMessengerBinding`). Each public Dart class has a corresponding test file in `test/`. Tests verify correct method names, argument serialization, and widget behavior — they do not call native code.

## Platform Requirements

- Flutter ≥ 3.22.0, Dart SDK ≥ 3.4.0
- Android: minSdk 23, compileSdk 34, Java/Kotlin 17
- iOS: 13.0+, Swift 5.0
