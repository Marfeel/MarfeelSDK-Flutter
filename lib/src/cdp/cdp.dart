import 'package:flutter/services.dart';

import '../method_channel.dart';
import 'models.dart';

/// Public entry point for the Customer Data Platform (CDP) subsystem: stable
/// visitor identity (`master_id`), read-only RFV/cohorts attached to beacons,
/// host-pushed segments + properties, and server-authoritative meters.
///
/// The whole subsystem is inert unless it was opted in at
/// `CompassTracking.initialize(..., enableCdp: true)` **and** personalization
/// consent is present. Otherwise every method below no-ops / returns empty and
/// no network call is made. The CDP is strictly fail-open — a CDP outage never
/// breaks page tracking.
///
/// All methods are asynchronous because they cross the platform method channel,
/// even where the underlying native call is synchronous.
class Cdp {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  Cdp._();

  /// Link a known external identifier (login id, CRM id, email hash…) to the
  /// current visitor. The backend may merge identities and adopt a different
  /// `master_id`.
  static void cdpDoIdentityLink(
    String type,
    String value, {
    bool isDeterministic = false,
  }) {
    _channel.invokeMethod('cdp.doIdentityLink', {
      'type': type,
      'value': value,
      'isDeterministic': isDeterministic,
    });
  }

  /// The CDP's contribution to a beacon: `master_id` + read-only rfv/cohorts.
  static Future<CdpData> getCdpData() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('cdp.getData');
    if (result == null) return const CdpData();
    return CdpData.fromMap(result);
  }

  /// The current `master_id`, or `null` if identity has not resolved yet.
  static Future<String?> getCdpMasterId() {
    return _channel.invokeMethod<String>('cdp.getMasterId');
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
