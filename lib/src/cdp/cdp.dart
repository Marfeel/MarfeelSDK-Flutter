import 'package:flutter/services.dart';

import '../method_channel.dart';
import 'models.dart';

/// Public entry point for the Customer Data Platform (CDP) subsystem: stable
/// visitor identity (`master_id`), read-only RFV/cohorts attached to beacons,
/// host-pushed segments + properties, Server Segments / Properties mirrored
/// from the CDP, server-authoritative meters and publisher consents.
///
/// The identity subsystem is inert unless it was opted in at
/// `CompassTracking.initialize(..., enableCdp: true)` **and** personalization
/// consent is present. Otherwise every identity method below no-ops / returns
/// empty and no network call is made. The publisher-consent methods
/// ([trackConsent], [getConsent], [hasConsent]) are gated on `enableCdp` only.
/// The CDP is strictly fail-open — a CDP outage never breaks page tracking.
///
/// All methods are asynchronous because they cross the platform method channel,
/// even where the underlying native call is synchronous.
class Cdp {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  Cdp._();

  /// Link an external identifier to the current visitor and adopt the master
  /// the CDP resolves it to. Completes once the link round-trip finishes (or
  /// is skipped for lack of consent).
  ///
  /// Rejects with an [ArgumentError] on an empty [type] or [value] instead of
  /// posting them: the failed request would cache empty rfv/cohorts over the
  /// real ones. See [CdpIdentityTypes] for the accepted types.
  static Future<void> setIdentity(
    String type,
    String value, {
    bool isDeterministic = false,
  }) async {
    if (type.isEmpty) {
      throw ArgumentError.value(type, 'type', 'Cdp.setIdentity: type is required');
    }
    if (value.isEmpty) {
      throw ArgumentError.value(
          value, 'value', 'Cdp.setIdentity: value is required');
    }
    await _channel.invokeMethod<void>('cdp.setIdentity', {
      'type': type,
      'value': value,
      'isDeterministic': isDeterministic,
    });
  }

  /// Unlink an identity from the current master. Without a [value], every
  /// identity of [type] the master owns is unlinked. Rejects with an
  /// [ArgumentError] on an empty [type].
  static Future<void> deleteIdentity(String type, {String? value}) async {
    if (type.isEmpty) {
      throw ArgumentError.value(
          type, 'type', 'Cdp.deleteIdentity: type is required');
    }
    await _channel.invokeMethod<void>('cdp.deleteIdentity', {
      'type': type,
      'value': value,
    });
  }

  /// Fire-and-forget identity link; failures are swallowed.
  @Deprecated('Use setIdentity, which completes once the link round-trip ends')
  static void cdpDoIdentityLink(
    String type,
    String value, {
    bool isDeterministic = false,
  }) {
    setIdentity(type, value, isDeterministic: isDeterministic)
        .catchError((Object _) {});
  }

  /// The CDP's contribution to a beacon: `master_id`, read-only rfv/cohorts
  /// and [CdpData.identityFresh].
  static Future<CdpData> getUserProfile() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('cdp.getUserProfile');
    if (result == null) return const CdpData();
    return CdpData.fromMap(result);
  }

  @Deprecated('Use getUserProfile')
  static Future<CdpData> getCdpData() => getUserProfile();

  /// The current `master_id`, or `null` if identity has not resolved yet.
  static Future<String?> getMasterId() {
    return _channel.invokeMethod<String>('cdp.getMasterId');
  }

  @Deprecated('Use getMasterId')
  static Future<String?> getCdpMasterId() => getMasterId();

  /// Record that the visitor accepted or rejected a publisher consent (a
  /// privacy policy, a newsletter opt-in). Not gated on personalization
  /// consent. Recorded under the current master when one exists; an anonymous
  /// decision is remembered on the device and replayed once a master exists.
  ///
  /// Resolves `null` on failure, when CDP is disabled, or when the decision
  /// has an empty `consentId` / `versionId`.
  static Future<CdpConsentRecordResponse?> trackConsent(
      CdpConsent decision) async {
    if (decision.consentId.isEmpty || decision.versionId.isEmpty) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'cdp.trackConsent',
        decision.toMap(),
      );
      if (result == null) return null;
      return CdpConsentRecordResponse.fromMap(result);
    } on PlatformException {
      return null;
    }
  }

  /// Read a consent's definition from the catalog. `null` when unknown, on
  /// failure, or when CDP is disabled.
  static Future<CdpConsentDefinition?> getConsent(CdpConsentRef ref) async {
    if (ref.consentId.isEmpty) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'cdp.getConsent',
        {'consentId': ref.consentId, 'versionId': ref.versionId},
      );
      if (result == null) return null;
      return CdpConsentDefinition.fromMap(result);
    } on PlatformException {
      return null;
    }
  }

  /// Whether the visitor has accepted the consent (at exactly
  /// [CdpConsentQuery.versionId] when given). `false` — never `null` — on
  /// failure and when CDP is disabled. Answered from the device's memory when
  /// it has neither a master nor an email to ask with.
  static Future<bool> hasConsent(CdpConsentQuery query) async {
    if (query.consentId.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>('cdp.hasConsent', {
        'consentId': query.consentId,
        'versionId': query.versionId,
        'email': query.email,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// `trim` + lower-case, the server's rule for emails.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// `trim` only — never case-folded; `+34600111222` and `600111222` stay two
  /// users.
  static String normalizePhone(String phone) => phone.trim();

  /// SHA-256 hex of [normalizeEmail]; send under [CdpIdentityTypes.emailSha256].
  static Future<String> hashEmail(String email) async {
    final result =
        await _channel.invokeMethod<String>('cdp.hashEmail', {'email': email});
    return result!;
  }

  /// SHA-256 hex of [normalizePhone]; send under [CdpIdentityTypes.phoneSha256].
  static Future<String> hashPhone(String phone) async {
    final result =
        await _channel.invokeMethod<String>('cdp.hashPhone', {'phone': phone});
    return result!;
  }

  /// Add one segment to the local CDP mirror (no-op if already present).
  static void addCdpSegment(String segment) {
    _channel.invokeMethod('cdp.addSegment', {'segment': segment});
  }

  /// Remove one segment from the local CDP mirror.
  static void removeCdpSegment(String segment) {
    _channel.invokeMethod('cdp.removeSegment', {'segment': segment});
  }

  /// Replace the full local CDP segment list (deduplicated).
  static void setCdpSegments(List<String> segments) {
    _channel.invokeMethod('cdp.setSegments', {'segments': segments});
  }

  /// Remove all CDP segments.
  static void clearCdpSegments() {
    _channel.invokeMethod('cdp.clearSegments');
  }

  /// Read the current local CDP segment mirror for the resolved identity.
  static Future<List<String>> getCdpSegments() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('cdp.getSegments');
    if (result == null) return const [];
    return result.cast<String>();
  }

  /// Server Segments (asserted by the CDP, not by this device) known right
  /// now, without resolving.
  static Future<List<String>> listServerSegments() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('cdp.listServerSegments');
    if (result == null) return const [];
    return result.cast<String>();
  }

  /// Server Segments after an identity resolve.
  static Future<List<String>> getServerSegments() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('cdp.getServerSegments');
    if (result == null) return const [];
    return result.cast<String>();
  }

  /// Server Properties (computed by the CDP) known right now, without
  /// resolving.
  static Future<Map<String, String>> listServerProperties() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('cdp.listServerProperties');
    if (result == null) return const {};
    return result.cast<String, String>();
  }

  /// Server Properties after an identity resolve.
  static Future<Map<String, String>> getServerProperties() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('cdp.getServerProperties');
    if (result == null) return const {};
    return result.cast<String, String>();
  }

  /// Refresh and return all meters (stale-while-revalidate; fail-open).
  static Future<List<MeterState>> getMeterSnapshot() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('cdp.getMeterSnapshot');
    if (result == null) return const [];
    return result
        .cast<Map<dynamic, dynamic>>()
        .map(MeterState.fromMap)
        .toList(growable: false);
  }

  /// Read a single meter from the in-memory mirror, or `null` if absent.
  static Future<MeterState?> getMeter(String name) async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('cdp.getMeter', {'name': name});
    if (result == null) return null;
    return MeterState.fromMap(result);
  }

  /// Read all meters currently held in the in-memory mirror.
  static Future<List<MeterState>> listMeters() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('cdp.listMeters');
    if (result == null) return const [];
    return result
        .cast<Map<dynamic, dynamic>>()
        .map(MeterState.fromMap)
        .toList(growable: false);
  }

  /// Increment a meter and return its new state.
  ///
  /// Throws [MeterNotFoundError] if the meter is not configured for the site.
  /// Returns `null` when the CDP is not ready (no consent / no `master_id`) or
  /// when the increment failed and no mirrored value is available.
  static Future<MeterState?> incrementMeter(String name) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'cdp.incrementMeter',
        {'name': name},
      );
      if (result == null) return null;
      return MeterState.fromMap(result);
    } on PlatformException catch (e) {
      if (e.code == 'METER_NOT_FOUND') {
        throw MeterNotFoundError(name);
      }
      rethrow;
    }
  }
}
