## 0.2.4

- Test groups can take their variant from a user var your app sets, when the group is configured that way in Experience Manager. Set the var with `CompassTracking.setUserVar` before calling `Experiences.fetchExperiences`. A reader whose value is missing or not mapped is out of the test: no experience from the group is returned and no variant is recorded, unless the group has a fallback variant.
- iOS: the minimum deployment target is now 15.0 (was 13.0), required by `MarfeelSDK-iOS` 2.19.1.
- Android: bumped `com.marfeel.compass:views` to `1.19.1`.
- iOS: bumped `MarfeelSDK-iOS` to `~> 2.19.1`.

## 0.2.3

- Experiments are now evaluated on the device like in the web SDK: losing variants are dropped and the control arm is returned by `Experiences.fetchExperiences`, marked through the new `Experience.experimentation` (`Experimentation(isControl, name)`, `null` outside an experiment). Check `isControl` before rendering: for the control arm keep your own module and still call the tracking methods.
- Test-group assignments are deterministic per user, stored in the `mrfExperiment_<groupId>` user vars, and cleared by `CompassTracking.resetUser()`.
- Recirculation events from `Experiences.trackEligible` / `trackImpression` / `trackClick` send the test version, and their module name is the base experience id.
- Android: bumped `com.marfeel.compass:views` to `1.19.0`.
- iOS: bumped `MarfeelSDK-iOS` to `~> 2.19.0`.

## 0.2.2

- `UserType.anonymous` is now `0` (was `1`), matching the web SDK; both native plugins still accept `1` as anonymous.
- Android: bumped `com.marfeel.compass:views` to `1.18.5`.
- iOS: bumped `MarfeelSDK-iOS` to `~> 2.18.17`.

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
