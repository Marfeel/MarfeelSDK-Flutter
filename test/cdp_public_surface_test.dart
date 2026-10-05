import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

// The public surface is add-only: every tear-off below must keep compiling.
// Old flat names stay as deprecated delegates.
void main() {
  test('every name on Cdp stays put', () {
    final names = <Object>[
      Cdp.setIdentity,
      Cdp.deleteIdentity,
      // ignore: deprecated_member_use_from_same_package
      Cdp.cdpDoIdentityLink,
      Cdp.getUserProfile,
      // ignore: deprecated_member_use_from_same_package
      Cdp.getCdpData,
      Cdp.getMasterId,
      // ignore: deprecated_member_use_from_same_package
      Cdp.getCdpMasterId,
      Cdp.trackConsent,
      Cdp.getConsent,
      Cdp.hasConsent,
      Cdp.normalizeEmail,
      Cdp.normalizePhone,
      Cdp.hashEmail,
      Cdp.hashPhone,
      Cdp.addCdpSegment,
      Cdp.removeCdpSegment,
      Cdp.setCdpSegments,
      Cdp.clearCdpSegments,
      Cdp.getCdpSegments,
      Cdp.listServerSegments,
      Cdp.getServerSegments,
      Cdp.listServerProperties,
      Cdp.getServerProperties,
      Cdp.getMeterSnapshot,
      Cdp.getMeter,
      Cdp.listMeters,
      Cdp.incrementMeter,
    ];
    expect(names, hasLength(27));
  });

  test('every CDP-adjacent name on CompassTracking stays put', () {
    final names = <Object>[
      CompassTracking.resetUser,
      CompassTracking.getUserSegments,
      CompassTracking.getUserSegmentsAsync,
      CompassTracking.getUserVars,
      CompassTracking.getUserVarsAsync,
      CompassTracking.setSiteUserId,
      CompassTracking.setUserVar,
      CompassTracking.addUserSegment,
      CompassTracking.setUserSegments,
      CompassTracking.removeUserSegment,
      CompassTracking.clearUserSegments,
      CompassTracking.setConsent,
      CompassTracking.getUserId,
      CompassTracking.getSessionId,
    ];
    expect(names, hasLength(14));
  });

  test('model types stay exported', () {
    const types = <Type>[
      CdpData,
      CdpRfv,
      CdpIdentityTypes,
      CdpConsent,
      CdpConsentStatus,
      CdpConsentRef,
      CdpConsentQuery,
      CdpConsentAcceptMethod,
      CdpConsentShowPolicy,
      CdpConsentVersion,
      CdpConsentDefinition,
      CdpConsentRecordResponse,
      MeterState,
      MeterWindow,
      MeterNotFoundError,
    ];
    expect(types, hasLength(15));
  });
}
