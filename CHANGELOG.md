## 0.2.1

- CDP identity: `Cdp.setIdentity` (completes once the link round-trip ends, rejects empty type/value), `Cdp.deleteIdentity`, `Cdp.getUserProfile` (with `identityFresh`), `Cdp.getMasterId`, `CdpIdentityTypes`, and device-side hashing (`hashEmail`, `hashPhone`, `normalizeEmail`, `normalizePhone`). `cdpDoIdentityLink`, `getCdpData` and `getCdpMasterId` are now deprecated aliases.
- Sign-out: `CompassTracking.resetUser()` rotates the local user and resets the CDP identity server-side.
- Server Segments / Properties: `Cdp.listServerSegments`, `getServerSegments`, `listServerProperties`, `getServerProperties`; `CompassTracking.getUserSegments` / `getUserVars` (+ `Async` variants) expose the merged values a beacon carries, trimmed to 100 segments with the `mrf_tooManySegments` user var.
- Publisher consents: `Cdp.trackConsent`, `getConsent`, `hasConsent` with the `CdpConsent*` models.
- Method channel: `cdp.doIdentityLink` and `cdp.getData` were replaced by `cdp.setIdentity` and `cdp.getUserProfile`.
- Android: bumped `com.marfeel.compass:views` to `1.18.3`.
- iOS: bumped `MarfeelSDK-iOS` to `~> 2.18.14`.

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
