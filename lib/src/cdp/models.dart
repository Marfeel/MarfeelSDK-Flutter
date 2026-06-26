// Data models for the Customer Data Platform (CDP) subsystem.
//
// These mirror the native `CdpData` / `MeterState` types exposed by the
// Marfeel Compass SDK on Android (`com.marfeel.compass.cdp.model`) and iOS
// (`MarfeelSDK_iOS`). The CDP logic itself lives in the native SDKs; the
// Flutter layer only carries these values across the method channel.

/// Read-only Recency / Frequency / Value score for the current visitor.
///
/// This is the **CDP** RFV (keyed by `master_id`), distinct from the legacy
/// [RFV] returned by `CompassTracking.getRFV`.
class CdpRfv {
  final int rfv;
  final int r;
  final int f;
  final int v;

  const CdpRfv({
    required this.rfv,
    required this.r,
    required this.f,
    required this.v,
  });

  factory CdpRfv.fromMap(Map<dynamic, dynamic> map) {
    return CdpRfv(
      rfv: (map['rfv'] as num).toInt(),
      r: (map['r'] as num).toInt(),
      f: (map['f'] as num).toInt(),
      v: (map['v'] as num).toInt(),
    );
  }

  @override
  String toString() => 'CdpRfv(rfv: $rfv, r: $r, f: $f, v: $v)';
}

/// The CDP's contribution to each tracking beacon: the stable visitor
/// `master_id` plus the read-only [rfv] and [cohorts].
class CdpData {
  final String? masterId;
  final CdpRfv? rfv;
  final List<int> cohorts;

  const CdpData({
    this.masterId,
    this.rfv,
    this.cohorts = const [],
  });

  factory CdpData.fromMap(Map<dynamic, dynamic> map) {
    final rfvRaw = map['rfv'];
    final cohortsRaw = map['cohorts'] as List<dynamic>?;
    return CdpData(
      masterId: map['masterId'] as String?,
      rfv: rfvRaw == null
          ? null
          : CdpRfv.fromMap(rfvRaw as Map<dynamic, dynamic>),
      cohorts: cohortsRaw == null
          ? const []
          : cohortsRaw.map((e) => (e as num).toInt()).toList(growable: false),
    );
  }

  @override
  String toString() =>
      'CdpData(masterId: $masterId, rfv: $rfv, cohorts: $cohorts)';
}

/// The reset window of a [MeterState] (calendar month, rolling 7 days, …).
class MeterWindow {
  final String duration;
  final String period;
  final String tz;

  const MeterWindow({
    this.duration = '',
    this.period = '',
    this.tz = '',
  });

  factory MeterWindow.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const MeterWindow();
    return MeterWindow(
      duration: map['duration'] as String? ?? '',
      period: map['period'] as String? ?? '',
      tz: map['tz'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'MeterWindow(duration: $duration, period: $period, tz: $tz)';
}

/// A server-authoritative counter (e.g. a metered paywall).
///
/// The [threshold] / [reached] / [remaining] trio is only present when the
/// meter has a threshold configured — they stay `null` otherwise.
class MeterState {
  final String name;
  final int count;
  final int? threshold;
  final bool? reached;
  final int? remaining;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final MeterWindow window;

  const MeterState({
    required this.name,
    this.count = 0,
    this.threshold,
    this.reached,
    this.remaining,
    this.startedAt,
    this.expiresAt,
    this.window = const MeterWindow(),
  });

  factory MeterState.fromMap(Map<dynamic, dynamic> map) {
    DateTime? toDate(Object? millis) => millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((millis as num).toInt());
    return MeterState(
      name: map['name'] as String? ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      threshold: (map['threshold'] as num?)?.toInt(),
      reached: map['reached'] as bool?,
      remaining: (map['remaining'] as num?)?.toInt(),
      startedAt: toDate(map['startedAt']),
      expiresAt: toDate(map['expiresAt']),
      window: MeterWindow.fromMap(map['window'] as Map<dynamic, dynamic>?),
    );
  }

  @override
  String toString() =>
      'MeterState(name: $name, count: $count, threshold: $threshold, '
      'reached: $reached, remaining: $remaining, window: $window)';
}

/// Thrown by `Cdp.incrementMeter` when the target meter is not configured for
/// the site (the backend answered with HTTP 404).
class MeterNotFoundError implements Exception {
  final String meterName;
  const MeterNotFoundError(this.meterName);

  @override
  String toString() => 'MeterNotFoundError: meter "$meterName" is not configured';
}
