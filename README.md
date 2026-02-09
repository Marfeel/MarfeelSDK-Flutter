# Marfeel SDK for Flutter

Flutter plugin for the [Marfeel Compass](https://www.marfeel.com) analytics SDK. Provides page tracking, scroll depth, multimedia events, conversions, and user engagement metrics on both Android and iOS.

## Platform requirements

| Platform | Minimum version |
|----------|----------------|
| Android  | API 23 (6.0)   |
| iOS      | 13.0           |
| Flutter  | 3.22.0         |
| Dart     | 3.4.0          |

## Installation

```yaml
dependencies:
  marfeel_sdk: ^0.1.0
```

### Android setup

Add the Marfeel Maven repository to your app's `android/build.gradle`:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://repositories.mrf.io/nexus/repository/mvn-marfeel-public/" }
    }
}
```

### iOS setup

No additional setup required. The native SDK is installed automatically via CocoaPods.

## Quick start

```dart
import 'package:marfeel_sdk/marfeel_sdk.dart';

// Initialize the SDK
CompassTracking.initialize('YOUR_ACCOUNT_ID');
CompassTracking.setConsent(true);
CompassTracking.setLandingPage('https://yoursite.com/');

// Track a screen
CompassTracking.trackScreen('home');
```

## Usage

### Page and screen tracking

```dart
// Track a web page by URL
CompassTracking.trackNewPage('https://yoursite.com/article/123');

// Track a named screen
CompassTracking.trackScreen('profile');

// Stop tracking the current page
CompassTracking.stopTracking();
```

### Scroll tracking

Wrap your scrollable content with `CompassScrollView` to automatically track scroll depth:

```dart
CompassScrollView(
  child: Column(
    children: [
      // Your content here
    ],
  ),
)
```

You can also report scroll percentage manually:

```dart
CompassTracking.updateScrollPercentage(75);
```

### Conversions

```dart
CompassTracking.trackConversion('signup');

// With options
CompassTracking.trackConversion(
  'purchase',
  options: ConversionOptions(
    initiator: 'checkout_button',
    id: 'order_123',
    value: '29.99',
    scope: ConversionScope.session,
    meta: {'currency': 'EUR'},
  ),
);
```

### User identity and segmentation

```dart
// Set user identity
CompassTracking.setSiteUserId('user_456');
CompassTracking.setUserType(UserType.logged);

// Get the Marfeel-assigned user ID
final userId = await CompassTracking.getUserId();

// User segments
CompassTracking.addUserSegment('premium');
CompassTracking.setUserSegments(['premium', 'newsletter']);
CompassTracking.removeUserSegment('newsletter');
CompassTracking.clearUserSegments();
```

### Custom variables and metrics

```dart
// Page-scoped
CompassTracking.setPageVar('category', 'technology');
CompassTracking.setPageMetric('wordCount', 1200);

// Session-scoped
CompassTracking.setSessionVar('theme', 'dark');

// User-scoped
CompassTracking.setUserVar('preferredLanguage', 'en');
```

### RFV metrics

```dart
final rfv = await CompassTracking.getRFV();
if (rfv != null) {
  print('RFV: ${rfv.rfv}, R: ${rfv.r}, F: ${rfv.f}, V: ${rfv.v}');
}
```

### Multimedia tracking

```dart
// Initialize a multimedia item
MultimediaTracking.initializeItem(
  id: 'video_1',
  provider: 'youtube',
  providerId: 'dQw4w9WgXcQ',
  type: MultimediaType.video,
  metadata: MultimediaMetadata(
    title: 'My Video',
    duration: 212,
  ),
);

// Track playback events
MultimediaTracking.registerEvent(
  id: 'video_1',
  event: MultimediaEvent.play,
  eventTime: 0,
);

MultimediaTracking.registerEvent(
  id: 'video_1',
  event: MultimediaEvent.pause,
  eventTime: 45,
);
```

Available multimedia events: `play`, `pause`, `end`, `updateCurrentTime`, `adPlay`, `mute`, `unmute`, `fullScreen`, `backScreen`, `enterViewport`, `leaveViewport`.

## Example app

See the [example](example/) directory for a complete sample app demonstrating all SDK features.

## License

MIT - see [LICENSE](LICENSE) for details.
