// Data models for the Customer Data Platform (CDP) subsystem.
//
// These mirror the native `CdpData` / `MeterState` / consent types exposed by
// the Marfeel Compass SDK on Android (`com.marfeel.compass.cdp.model`) and iOS
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
///
/// [identityFresh] is true only when *this* process round-tripped an identity
/// resolve or link that returned a `master_id` **and** mirrored its Server
/// Segments / Properties. A warm cache never counts.
class CdpData {
  final String? masterId;
  final CdpRfv? rfv;
  final List<int> cohorts;
  final bool identityFresh;

  const CdpData({
    this.masterId,
    this.rfv,
    this.cohorts = const [],
    this.identityFresh = false,
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
      identityFresh: map['identityFresh'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'CdpData(masterId: $masterId, rfv: $rfv, '
      'cohorts: $cohorts, identityFresh: $identityFresh)';
}

/// The identity types the CDP accepts in `Cdp.setIdentity` / `deleteIdentity`.
///
/// [stable] types identify a registered user and are kept permanently;
/// [deviceBound] types are anonymous and age out 180 days after the last
/// write. Hash emails and phones on the device with `Cdp.hashEmail` /
/// `Cdp.hashPhone` and send them under [emailSha256] / [phoneSha256].
class CdpIdentityTypes {
  CdpIdentityTypes._();

  static const email = 'email';
  static const emailSha256 = 'email_sha256';
  static const phone = 'phone';
  static const phoneSha256 = 'phone_sha256';
  static const externalId = 'external_id';
  static const customerId = 'customer_id';
  static const registeredUserId = 'registered_user_id';

  static const loginId = 'login_id';
  static const crmId = 'crm_id';
  static const cookie = 'cookie';
  static const deviceId = 'device_id';
  static const maid = 'maid';
  static const idfa = 'idfa';
  static const idfv = 'idfv';
  static const rampid = 'rampid';
  static const pushToken = 'push_token';

  static const Set<String> stable = {
    email,
    emailSha256,
    phone,
    phoneSha256,
    externalId,
    customerId,
    registeredUserId,
  };

  static const Set<String> deviceBound = {
    loginId,
    crmId,
    cookie,
    deviceId,
    maid,
    idfa,
    idfv,
    rampid,
    pushToken,
  };

  static const Set<String> all = {...stable, ...deviceBound};
}

/// Whether the visitor accepted or rejected a publisher consent.
///
/// Publisher consents (a privacy policy, a newsletter opt-in) are unrelated to
/// the CMP consent set through `CompassTracking.setConsent`, which gates
/// tracking.
enum CdpConsentStatus {
  accepted('accepted'),
  rejected('rejected');

  const CdpConsentStatus(this.wireValue);
  final String wireValue;
}

/// A consent decision, see `Cdp.trackConsent`.
class CdpConsent {
  final String consentId;

  /// The version's id from CDP > Settings > Consents. Opaque: sent verbatim.
  final String versionId;
  final CdpConsentStatus status;
  final Map<String, String>? metadata;

  /// Linked to the master when one exists (as `setIdentity` would); otherwise
  /// the subject of the decision. Hashed on the device before it leaves.
  final String? email;

  const CdpConsent({
    required this.consentId,
    required this.versionId,
    required this.status,
    this.metadata,
    this.email,
  });

  Map<String, dynamic> toMap() => {
        'consentId': consentId,
        'versionId': versionId,
        'status': status.wireValue,
        'metadata': metadata ?? const <String, String>{},
        'email': email,
      };
}

/// Catalog lookup, see `Cdp.getConsent`.
class CdpConsentRef {
  final String consentId;

  /// Absent → the consent's default version, as configured in Compass.
  final String? versionId;

  const CdpConsentRef({required this.consentId, this.versionId});
}

/// Status lookup, see `Cdp.hasConsent`.
class CdpConsentQuery {
  final String consentId;

  /// When given, only an accept at exactly this version counts. Absent → any
  /// accepted version.
  final String? versionId;

  /// Sent alongside the master when both exist, so an email accepted elsewhere
  /// answers before it is linked here.
  final String? email;

  const CdpConsentQuery({required this.consentId, this.versionId, this.email});
}

/// How the visitor signals consent. Carried through **verbatim** from the
/// server, so [CdpConsentDefinition.acceptMethod] is a plain string; these are
/// the known values.
class CdpConsentAcceptMethod {
  CdpConsentAcceptMethod._();

  static const checkBox = 'check-box';
  static const preChecked = 'pre-checked';

  /// Show no box at all — submitting the form is the consent.
  static const formSubmit = 'form-submit';
}

/// Whether a visitor who already accepted is prompted again.
enum CdpConsentShowPolicy {
  always('always'),
  ifNotAccepted('if-not-accepted');

  const CdpConsentShowPolicy(this.wireValue);
  final String wireValue;

  /// Only the exact string `if-not-accepted` survives; anything else folds to
  /// [always] — prompting again is recoverable, suppressing a prompt is not.
  static CdpConsentShowPolicy fromWire(Object? value) =>
      value == ifNotAccepted.wireValue ? ifNotAccepted : always;
}

class CdpConsentVersion {
  final String versionId;
  final String label;
  final String? date;
  final String? displayPrompt;
  final String? errorMessage;
  final Map<String, String> metadata;

  const CdpConsentVersion({
    required this.versionId,
    required this.label,
    this.date,
    this.displayPrompt,
    this.errorMessage,
    this.metadata = const {},
  });

  factory CdpConsentVersion.fromMap(Map<dynamic, dynamic> map) {
    return CdpConsentVersion(
      versionId: map['versionId']?.toString() ?? '',
      label: map['label'] as String? ?? '',
      date: map['date'] as String?,
      displayPrompt: map['displayPrompt'] as String?,
      errorMessage: map['errorMessage'] as String?,
      metadata: _stringMap(map['metadata']),
    );
  }

  @override
  String toString() =>
      'CdpConsentVersion(versionId: $versionId, label: $label, date: $date)';
}

/// A consent's definition from the catalog, see `Cdp.getConsent`.
class CdpConsentDefinition {
  final String consentId;
  final String name;
  final String? purpose;
  final bool mandatory;

  /// Render the box accordingly — [CdpConsentAcceptMethod.formSubmit] means
  /// show no box at all. Verbatim from the server; empty when none is
  /// configured.
  final String acceptMethod;

  /// Pair [CdpConsentShowPolicy.ifNotAccepted] with `Cdp.hasConsent` — this is
  /// config, not a verdict.
  final CdpConsentShowPolicy showPolicy;

  /// `null` when the consent has no default version and none was requested.
  final CdpConsentVersion? version;

  const CdpConsentDefinition({
    required this.consentId,
    required this.name,
    this.purpose,
    this.mandatory = false,
    this.acceptMethod = '',
    this.showPolicy = CdpConsentShowPolicy.always,
    this.version,
  });

  factory CdpConsentDefinition.fromMap(Map<dynamic, dynamic> map) {
    final versionRaw = map['version'];
    return CdpConsentDefinition(
      consentId: map['consentId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      purpose: map['purpose'] as String?,
      mandatory: map['mandatory'] as bool? ?? false,
      acceptMethod: map['acceptMethod'] as String? ?? '',
      showPolicy: CdpConsentShowPolicy.fromWire(map['showPolicy']),
      version: versionRaw == null
          ? null
          : CdpConsentVersion.fromMap(versionRaw as Map<dynamic, dynamic>),
    );
  }

  @override
  String toString() => 'CdpConsentDefinition(consentId: $consentId, '
      'name: $name, mandatory: $mandatory, acceptMethod: $acceptMethod, '
      'showPolicy: $showPolicy, version: $version)';
}

/// The answer to `Cdp.trackConsent`.
class CdpConsentRecordResponse {
  /// The canonical master; may differ from the SDK's after a merge, in which
  /// case the SDK adopts it. `null` for an anonymous decision.
  final String? masterId;
  final String? consentId;
  final String? consentVersionId;

  /// The server's short vocabulary: `accept` / `reject`.
  final String? status;
  final bool recorded;
  final bool stored;

  const CdpConsentRecordResponse({
    this.masterId,
    this.consentId,
    this.consentVersionId,
    this.status,
    this.recorded = false,
    this.stored = false,
  });

  factory CdpConsentRecordResponse.fromMap(Map<dynamic, dynamic> map) {
    final masterId = map['masterId'] as String?;
    return CdpConsentRecordResponse(
      masterId: masterId == null || masterId.isEmpty ? null : masterId,
      consentId: map['consentId'] as String?,
      consentVersionId: map['consentVersionId']?.toString(),
      status: map['status'] as String?,
      recorded: map['recorded'] as bool? ?? false,
      stored: map['stored'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'CdpConsentRecordResponse(masterId: $masterId, '
      'consentId: $consentId, consentVersionId: $consentVersionId, '
      'status: $status, recorded: $recorded, stored: $stored)';
}

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) return const {};
  return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
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
