## 0.2.0

- Added CDP support via the `Cdp` API: identity linking (`cdpDoIdentityLink`), master id (`getCdpMasterId`), CDP data (`getCdpData`), segment management (`addCdpSegment`, `removeCdpSegment`, `setCdpSegments`, `clearCdpSegments`, `getCdpSegments`), and metered counters (`getMeterSnapshot`, `getMeter`, `listMeters`, `incrementMeter`).
- `CompassTracking.initialize` gained an `enableCdp` flag (defaults to `false`) to opt in to the CDP subsystem.
- Android: bumped `com.marfeel.compass:views` to `1.18.1`.
- iOS: bumped `MarfeelSDK-iOS` to `~> 2.18.11`.

## 0.1.1

- iOS: `trackConversion` now also sets a `ios-trackConversion` page var with value `"<conversion>:<id>"` for internal diagnostics of duplicated conversion calls.

## 0.1.0

- Initial release.
- Page and screen tracking via `CompassTracking`.
- Automatic scroll depth tracking with `CompassScrollView`.
- Multimedia (video/audio) tracking via `MultimediaTracking`.
- Conversion tracking with scoped options.
- User segmentation and custom variables.
- RFV (Recency, Frequency, Volume) metrics.
- Consent management.
- Android and iOS platform support.
