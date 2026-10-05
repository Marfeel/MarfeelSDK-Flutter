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
  marfeel_sdk: ^0.2.1
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

// Initialize the SDK (pass enableCdp: true to opt into the CDP subsystem)
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

### Customer Data Platform (CDP)

The CDP assigns a stable visitor `master_id`, carries read-only RFV + cohorts,
lets you push segments, mirrors the Server Segments / Server Properties the CDP
computes for the visitor, exposes server-authoritative meters (e.g. metered
paywalls) and records publisher consents. It is strictly fail-open: a CDP
outage never breaks tracking.

The identity subsystem is gated behind **two** conditions — both must hold or
every identity call no-ops and no network request is made:

1. The `enableCdp: true` opt-in at `initialize`.
2. Personalization consent (`CompassTracking.setConsent(true)`).

```dart
// Opt in at initialization
CompassTracking.initialize('YOUR_ACCOUNT_ID', enableCdp: true);
CompassTracking.setConsent(true);
```

#### Identity

```dart
// Link a known identifier to the current visitor. Completes once the link
// round-trip finishes; throws ArgumentError on an empty type or value.
await Cdp.setIdentity(CdpIdentityTypes.registeredUserId, 'user_456',
    isDeterministic: true);

// Emails and phones are hashed on the device before they leave
final digest = await Cdp.hashEmail(' Foo@Bar.com ');   // trim + lower-case, SHA-256 hex
await Cdp.setIdentity(CdpIdentityTypes.emailSha256, digest);
await Cdp.setIdentity(CdpIdentityTypes.phoneSha256, await Cdp.hashPhone('+34600111222'));

// Unlink one identity, or every identity of a type
await Cdp.deleteIdentity(CdpIdentityTypes.emailSha256, value: digest);
await Cdp.deleteIdentity(CdpIdentityTypes.registeredUserId);

// Read the resolved identity
final masterId = await Cdp.getMasterId();
final profile = await Cdp.getUserProfile(); // masterId, rfv, cohorts, identityFresh
```

`CdpIdentityTypes` lists the accepted types: the `stable` ones identify a
registered user and are kept permanently, the `deviceBound` ones are anonymous
and age out 180 days after the last write.

#### Sign-out

```dart
// Forget the current user on the device (new user id, session, user vars,
// segments, CDP identity and caches) and reset the identity server-side.
// Keeps the CMP consent. Never throws; completes within ~5 s.
await CompassTracking.resetUser();
```

#### Segments and Server Segments / Properties

```dart
// Device-owned CDP segments (separate from the legacy CompassTracking.*UserSegment APIs)
Cdp.addCdpSegment('sports_fan');
Cdp.setCdpSegments(['sports_fan', 'subscriber']);
Cdp.removeCdpSegment('sports_fan');
Cdp.clearCdpSegments();
final segments = await Cdp.getCdpSegments();

// Segments and properties the CDP asserts for this visitor
final serverSegments = await Cdp.listServerSegments();     // known right now
final resolvedSegments = await Cdp.getServerSegments();    // after an identity resolve
final serverProperties = await Cdp.listServerProperties();
final resolvedProperties = await Cdp.getServerProperties();

// What a beacon carries: Server Segments first, then device-owned ones,
// deduplicated and trimmed to 100; Server Properties under device-owned vars.
final useg = await CompassTracking.getUserSegments();
final uvar = await CompassTracking.getUserVars();
```

Server Segments cannot be claimed through `CompassTracking.setUserSegments`;
use `addUserSegment` to take ownership of one. When the union exceeds 100
segments the user var `mrf_tooManySegments` is set to `"true"`.

#### Publisher consents

Publisher consents (a privacy policy, a newsletter opt-in) are unrelated to the
CMP consent set through `setConsent`. They only require `enableCdp: true`.

```dart
final record = await Cdp.trackConsent(CdpConsent(
  consentId: 'privacy_policy',
  versionId: '3',
  status: CdpConsentStatus.accepted,
  metadata: {'source': 'settings'},
  email: 'foo@bar.com', // optional; hashed on the device
));
// null on failure or when CDP is disabled; an anonymous decision is
// remembered on the device and replayed once a master_id exists.

final definition = await Cdp.getConsent(CdpConsentRef(consentId: 'privacy_policy'));
if (definition?.acceptMethod == CdpConsentAcceptMethod.formSubmit) {
  // show no checkbox — submitting the form is the consent
}
if (definition?.showPolicy == CdpConsentShowPolicy.ifNotAccepted &&
    await Cdp.hasConsent(CdpConsentQuery(consentId: 'privacy_policy'))) {
  // already accepted — skip the prompt
}
```

#### Meters

```dart
final meters = await Cdp.getMeterSnapshot();   // refresh + return all meters
final meter = await Cdp.getMeter('paywall');   // cached read of one meter
final all = await Cdp.listMeters();            // cached read of all meters

try {
  final updated = await Cdp.incrementMeter('paywall');
  print('count: ${updated?.count} / ${updated?.threshold}');
} on MeterNotFoundError catch (e) {
  print('Meter "${e.meterName}" is not configured for this site');
}
```

> The CDP segment APIs (`addCdpSegment`, `setCdpSegments`, …) are **separate**
> from the legacy `CompassTracking.addUserSegment` / `setUserSegments` family,
> which remain unchanged. `cdpDoIdentityLink`, `getCdpData` and
> `getCdpMasterId` are deprecated aliases of `setIdentity`, `getUserProfile`
> and `getMasterId`.

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
