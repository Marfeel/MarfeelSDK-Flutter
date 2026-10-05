import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';
import 'package:marfeel_sdk/src/method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  Object? Function(MethodCall)? responder;

  setUp(() {
    calls = [];
    responder = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, (call) async {
      calls.add(call);
      return responder?.call(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, null);
  });

  group('initialize enableCdp', () {
    test('defaults to false', () {
      CompassTracking.initialize('123');
      expect(calls.last.method, 'initialize');
      expect((calls.last.arguments as Map)['enableCdp'], false);
    });

    test('forwards true', () {
      CompassTracking.initialize('123', enableCdp: true);
      expect((calls.last.arguments as Map)['enableCdp'], true);
    });
  });

  group('identity', () {
    test('setIdentity sends type/value/isDeterministic and completes',
        () async {
      await Cdp.setIdentity('registered_user_id', 'user_456',
          isDeterministic: true);
      expect(calls.last.method, 'cdp.setIdentity');
      expect(calls.last.arguments, {
        'type': 'registered_user_id',
        'value': 'user_456',
        'isDeterministic': true,
      });
    });

    test('setIdentity defaults isDeterministic to false', () async {
      await Cdp.setIdentity(CdpIdentityTypes.emailSha256, 'abc');
      expect((calls.last.arguments as Map)['isDeterministic'], false);
    });

    test('setIdentity rejects an empty type without touching the channel',
        () async {
      await expectLater(
          Cdp.setIdentity('', 'abc'), throwsA(isA<ArgumentError>()));
      expect(calls, isEmpty);
    });

    test('setIdentity rejects an empty value without touching the channel',
        () async {
      await expectLater(Cdp.setIdentity('email_sha256', ''),
          throwsA(isA<ArgumentError>()));
      expect(calls, isEmpty);
    });

    test('deleteIdentity sends type and value', () async {
      await Cdp.deleteIdentity('email_sha256', value: 'abc');
      expect(calls.last.method, 'cdp.deleteIdentity');
      expect(calls.last.arguments, {'type': 'email_sha256', 'value': 'abc'});
    });

    test('deleteIdentity without value sends null', () async {
      await Cdp.deleteIdentity('email_sha256');
      expect(calls.last.arguments, {'type': 'email_sha256', 'value': null});
    });

    test('deleteIdentity rejects an empty type', () async {
      await expectLater(
          Cdp.deleteIdentity(''), throwsA(isA<ArgumentError>()));
      expect(calls, isEmpty);
    });

    test('cdpDoIdentityLink delegates to cdp.setIdentity and swallows errors',
        () async {
      responder = (_) => throw PlatformException(code: 'ERROR');
      // ignore: deprecated_member_use_from_same_package
      Cdp.cdpDoIdentityLink('registered_user_id', 'user@example.com',
          isDeterministic: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls.last.method, 'cdp.setIdentity');
      expect(calls.last.arguments, {
        'type': 'registered_user_id',
        'value': 'user@example.com',
        'isDeterministic': true,
      });
    });

    test('getUserProfile parses masterId/rfv/cohorts/identityFresh', () async {
      responder = (_) => {
            'masterId': 'mid-1',
            'rfv': {'rfv': 42, 'r': 3, 'f': 5, 'v': 7},
            'cohorts': [101, 204],
            'identityFresh': true,
          };
      final data = await Cdp.getUserProfile();
      expect(calls.last.method, 'cdp.getUserProfile');
      expect(data.masterId, 'mid-1');
      expect(data.rfv?.rfv, 42);
      expect(data.rfv?.r, 3);
      expect(data.cohorts, [101, 204]);
      expect(data.identityFresh, isTrue);
    });

    test('getUserProfile handles null/empty', () async {
      responder = (_) => null;
      final data = await Cdp.getUserProfile();
      expect(data.masterId, isNull);
      expect(data.rfv, isNull);
      expect(data.cohorts, isEmpty);
      expect(data.identityFresh, isFalse);
    });

    test('getUserProfile handles missing rfv and identityFresh', () async {
      responder = (_) => {'masterId': null, 'rfv': null, 'cohorts': <int>[]};
      final data = await Cdp.getUserProfile();
      expect(data.rfv, isNull);
      expect(data.cohorts, isEmpty);
      expect(data.identityFresh, isFalse);
    });

    test('getCdpData delegates to getUserProfile', () async {
      responder = (_) => {'masterId': 'mid-3'};
      // ignore: deprecated_member_use_from_same_package
      final data = await Cdp.getCdpData();
      expect(calls.last.method, 'cdp.getUserProfile');
      expect(data.masterId, 'mid-3');
    });

    test('getMasterId returns value', () async {
      responder = (_) => 'mid-2';
      expect(await Cdp.getMasterId(), 'mid-2');
      expect(calls.last.method, 'cdp.getMasterId');
    });

    test('getCdpMasterId delegates to getMasterId', () async {
      responder = (_) => 'mid-2';
      // ignore: deprecated_member_use_from_same_package
      expect(await Cdp.getCdpMasterId(), 'mid-2');
      expect(calls.last.method, 'cdp.getMasterId');
    });
  });

  group('identity types', () {
    test('lists the 16 types and omits email_hash / phone_hash', () {
      expect(CdpIdentityTypes.all, hasLength(16));
      expect(CdpIdentityTypes.stable, hasLength(7));
      expect(CdpIdentityTypes.deviceBound, hasLength(9));
      expect(CdpIdentityTypes.stable.intersection(CdpIdentityTypes.deviceBound),
          isEmpty);
      expect(CdpIdentityTypes.all, isNot(contains('email_hash')));
      expect(CdpIdentityTypes.all, isNot(contains('phone_hash')));
      expect(CdpIdentityTypes.emailSha256, 'email_sha256');
      expect(CdpIdentityTypes.phoneSha256, 'phone_sha256');
      expect(CdpIdentityTypes.registeredUserId, 'registered_user_id');
    });
  });

  group('hashing', () {
    test('normalizeEmail trims and lower-cases', () {
      expect(Cdp.normalizeEmail('  Foo@Bar.COM '), 'foo@bar.com');
    });

    test('normalizePhone only trims', () {
      expect(Cdp.normalizePhone(' +34600111222 '), '+34600111222');
      expect(Cdp.normalizePhone('ABC'), 'ABC');
    });

    test('hashEmail asks native with the raw email', () async {
      responder = (_) =>
          '0c7e6a405862e402eb76a70f8a26fc732d07c32931e9fae9ab1582911d2e8a3b';
      final digest = await Cdp.hashEmail(' Foo@Bar.com ');
      expect(calls.last.method, 'cdp.hashEmail');
      expect(calls.last.arguments, {'email': ' Foo@Bar.com '});
      expect(digest,
          '0c7e6a405862e402eb76a70f8a26fc732d07c32931e9fae9ab1582911d2e8a3b');
    });

    test('hashPhone asks native with the raw phone', () async {
      responder = (_) =>
          'cb24629d1dbeb6ee24e7c20610896274e8102e67aa6efc2f3a1be2893c38008b';
      final digest = await Cdp.hashPhone('+34600111222');
      expect(calls.last.method, 'cdp.hashPhone');
      expect(calls.last.arguments, {'phone': '+34600111222'});
      expect(digest,
          'cb24629d1dbeb6ee24e7c20610896274e8102e67aa6efc2f3a1be2893c38008b');
    });
  });

  group('publisher consents', () {
    test('trackConsent sends the decision and parses the record', () async {
      responder = (_) => {
            'masterId': 'mid-1',
            'consentId': 'privacy',
            'consentVersionId': '3',
            'status': 'accept',
            'recorded': true,
            'stored': true,
          };
      final record = await Cdp.trackConsent(const CdpConsent(
        consentId: 'privacy',
        versionId: '3',
        status: CdpConsentStatus.accepted,
        metadata: {'source': 'settings'},
        email: 'foo@bar.com',
      ));
      expect(calls.last.method, 'cdp.trackConsent');
      expect(calls.last.arguments, {
        'consentId': 'privacy',
        'versionId': '3',
        'status': 'accepted',
        'metadata': {'source': 'settings'},
        'email': 'foo@bar.com',
      });
      expect(record?.masterId, 'mid-1');
      expect(record?.consentId, 'privacy');
      expect(record?.consentVersionId, '3');
      expect(record?.status, 'accept');
      expect(record?.recorded, isTrue);
      expect(record?.stored, isTrue);
    });

    test('trackConsent defaults metadata to {} and email to null', () async {
      await Cdp.trackConsent(const CdpConsent(
        consentId: 'newsletter',
        versionId: '1',
        status: CdpConsentStatus.rejected,
      ));
      expect(calls.last.arguments, {
        'consentId': 'newsletter',
        'versionId': '1',
        'status': 'rejected',
        'metadata': <String, String>{},
        'email': null,
      });
    });

    test('trackConsent returns null without calling native on missing ids',
        () async {
      expect(
          await Cdp.trackConsent(const CdpConsent(
              consentId: '', versionId: '1', status: CdpConsentStatus.accepted)),
          isNull);
      expect(
          await Cdp.trackConsent(const CdpConsent(
              consentId: 'x', versionId: '', status: CdpConsentStatus.accepted)),
          isNull);
      expect(calls, isEmpty);
    });

    test('trackConsent null -> null and empty masterId -> null', () async {
      responder = (_) => null;
      expect(
          await Cdp.trackConsent(const CdpConsent(
              consentId: 'x', versionId: '1', status: CdpConsentStatus.accepted)),
          isNull);
      responder = (_) => {'masterId': '', 'recorded': true, 'stored': false};
      final record = await Cdp.trackConsent(const CdpConsent(
          consentId: 'x', versionId: '1', status: CdpConsentStatus.accepted));
      expect(record?.masterId, isNull);
      expect(record?.recorded, isTrue);
      expect(record?.stored, isFalse);
    });

    test('getConsent sends consentId/versionId and parses the definition',
        () async {
      responder = (_) => {
            'consentId': 'privacy',
            'name': 'Privacy policy',
            'purpose': 'Legal',
            'mandatory': true,
            'acceptMethod': 'form-submit',
            'showPolicy': 'if-not-accepted',
            'version': {
              'versionId': '3',
              'label': 'v3',
              'date': '2026-01-01',
              'displayPrompt': 'I agree',
              'errorMessage': 'Required',
              'metadata': {'lang': 'en'},
            },
          };
      final definition = await Cdp.getConsent(
          const CdpConsentRef(consentId: 'privacy', versionId: '3'));
      expect(calls.last.method, 'cdp.getConsent');
      expect(calls.last.arguments, {'consentId': 'privacy', 'versionId': '3'});
      expect(definition?.consentId, 'privacy');
      expect(definition?.name, 'Privacy policy');
      expect(definition?.purpose, 'Legal');
      expect(definition?.mandatory, isTrue);
      expect(definition?.acceptMethod, CdpConsentAcceptMethod.formSubmit);
      expect(definition?.showPolicy, CdpConsentShowPolicy.ifNotAccepted);
      expect(definition?.version?.versionId, '3');
      expect(definition?.version?.label, 'v3');
      expect(definition?.version?.displayPrompt, 'I agree');
      expect(definition?.version?.metadata, {'lang': 'en'});
    });

    test('getConsent without version sends null and tolerates a bare answer',
        () async {
      responder = (_) => {
            'consentId': 'privacy',
            'name': 'Privacy policy',
            'showPolicy': 'IF-NOT-ACCEPTED',
          };
      final definition =
          await Cdp.getConsent(const CdpConsentRef(consentId: 'privacy'));
      expect(calls.last.arguments, {'consentId': 'privacy', 'versionId': null});
      expect(definition?.mandatory, isFalse);
      expect(definition?.acceptMethod, '');
      expect(definition?.showPolicy, CdpConsentShowPolicy.always);
      expect(definition?.version, isNull);
    });

    test('getConsent null -> null and empty id -> null', () async {
      responder = (_) => null;
      expect(await Cdp.getConsent(const CdpConsentRef(consentId: 'privacy')),
          isNull);
      calls.clear();
      expect(await Cdp.getConsent(const CdpConsentRef(consentId: '')), isNull);
      expect(calls, isEmpty);
    });

    test('hasConsent sends consentId/versionId/email and returns the verdict',
        () async {
      responder = (_) => true;
      final granted = await Cdp.hasConsent(const CdpConsentQuery(
          consentId: 'privacy', versionId: '3', email: 'foo@bar.com'));
      expect(calls.last.method, 'cdp.hasConsent');
      expect(calls.last.arguments, {
        'consentId': 'privacy',
        'versionId': '3',
        'email': 'foo@bar.com',
      });
      expect(granted, isTrue);
    });

    test('hasConsent is false, never null, on null / empty id', () async {
      responder = (_) => null;
      expect(await Cdp.hasConsent(const CdpConsentQuery(consentId: 'privacy')),
          isFalse);
      calls.clear();
      expect(await Cdp.hasConsent(const CdpConsentQuery(consentId: '')),
          isFalse);
      expect(calls, isEmpty);
    });

    test('consent calls fail open on a PlatformException', () async {
      responder = (_) => throw PlatformException(code: 'ERROR', message: 'x');
      expect(
          await Cdp.trackConsent(const CdpConsent(
              consentId: 'x', versionId: '1', status: CdpConsentStatus.accepted)),
          isNull);
      expect(await Cdp.getConsent(const CdpConsentRef(consentId: 'x')), isNull);
      expect(await Cdp.hasConsent(const CdpConsentQuery(consentId: 'x')),
          isFalse);
      expect(calls, hasLength(3));
    });

    test('CdpConsentShowPolicy.fromWire folds to always unless exact', () {
      expect(CdpConsentShowPolicy.fromWire('if-not-accepted'),
          CdpConsentShowPolicy.ifNotAccepted);
      expect(CdpConsentShowPolicy.fromWire('always'),
          CdpConsentShowPolicy.always);
      expect(CdpConsentShowPolicy.fromWire('If-Not-Accepted'),
          CdpConsentShowPolicy.always);
      expect(
          CdpConsentShowPolicy.fromWire(null), CdpConsentShowPolicy.always);
    });
  });

  group('server segments and properties', () {
    test('listServerSegments parses list', () async {
      responder = (_) => <dynamic>['srv_a', 'srv_b'];
      expect(await Cdp.listServerSegments(), ['srv_a', 'srv_b']);
      expect(calls.last.method, 'cdp.listServerSegments');
    });

    test('getServerSegments parses list and null -> empty', () async {
      responder = (_) => <dynamic>['srv_a'];
      expect(await Cdp.getServerSegments(), ['srv_a']);
      expect(calls.last.method, 'cdp.getServerSegments');
      responder = (_) => null;
      expect(await Cdp.getServerSegments(), isEmpty);
    });

    test('listServerProperties parses map', () async {
      responder = (_) => <dynamic, dynamic>{'tier': 'gold'};
      expect(await Cdp.listServerProperties(), {'tier': 'gold'});
      expect(calls.last.method, 'cdp.listServerProperties');
    });

    test('getServerProperties parses map and null -> empty', () async {
      responder = (_) => <dynamic, dynamic>{'tier': 'gold'};
      expect(await Cdp.getServerProperties(), {'tier': 'gold'});
      expect(calls.last.method, 'cdp.getServerProperties');
      responder = (_) => null;
      expect(await Cdp.getServerProperties(), isEmpty);
    });
  });

  group('segments', () {
    test('addCdpSegment', () {
      Cdp.addCdpSegment('sports_fan');
      expect(calls.last.method, 'cdp.addSegment');
      expect(calls.last.arguments, {'segment': 'sports_fan'});
    });

    test('removeCdpSegment', () {
      Cdp.removeCdpSegment('churned');
      expect(calls.last.method, 'cdp.removeSegment');
      expect(calls.last.arguments, {'segment': 'churned'});
    });

    test('setCdpSegments', () {
      Cdp.setCdpSegments(['a', 'b']);
      expect(calls.last.method, 'cdp.setSegments');
      expect(calls.last.arguments, {
        'segments': ['a', 'b']
      });
    });

    test('clearCdpSegments', () {
      Cdp.clearCdpSegments();
      expect(calls.last.method, 'cdp.clearSegments');
    });

    test('getCdpSegments parses list', () async {
      responder = (_) => <dynamic>['a', 'b'];
      final segments = await Cdp.getCdpSegments();
      expect(calls.last.method, 'cdp.getSegments');
      expect(segments, ['a', 'b']);
    });

    test('getCdpSegments null -> empty', () async {
      responder = (_) => null;
      expect(await Cdp.getCdpSegments(), isEmpty);
    });
  });

  group('meters', () {
    Map<String, dynamic> meterMap() => {
          'name': 'paywall',
          'count': 3,
          'threshold': 5,
          'reached': false,
          'remaining': 2,
          'startedAt': 1700000000000,
          'expiresAt': 1701000000000,
          'window': {'duration': 'calendar', 'period': 'P1M', 'tz': 'Europe/Madrid'},
        };

    test('getMeterSnapshot parses meters', () async {
      responder = (_) => <dynamic>[meterMap()];
      final meters = await Cdp.getMeterSnapshot();
      expect(calls.last.method, 'cdp.getMeterSnapshot');
      expect(meters, hasLength(1));
      final m = meters.first;
      expect(m.name, 'paywall');
      expect(m.count, 3);
      expect(m.threshold, 5);
      expect(m.reached, false);
      expect(m.remaining, 2);
      expect(m.startedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(m.window.duration, 'calendar');
      expect(m.window.period, 'P1M');
      expect(m.window.tz, 'Europe/Madrid');
    });

    test('meter without threshold keeps the trio null', () async {
      responder = (_) => <dynamic>[
            {
              'name': 'views',
              'count': 1,
              'window': {'duration': '', 'period': '', 'tz': ''},
            }
          ];
      final meters = await Cdp.getMeterSnapshot();
      final m = meters.first;
      expect(m.threshold, isNull);
      expect(m.reached, isNull);
      expect(m.remaining, isNull);
      expect(m.startedAt, isNull);
    });

    test('getMeter returns null when absent', () async {
      responder = (_) => null;
      expect(await Cdp.getMeter('missing'), isNull);
      expect(calls.last.method, 'cdp.getMeter');
      expect(calls.last.arguments, {'name': 'missing'});
    });

    test('getMeter parses single meter', () async {
      responder = (_) => meterMap();
      final m = await Cdp.getMeter('paywall');
      expect(m?.name, 'paywall');
    });

    test('listMeters parses list', () async {
      responder = (_) => <dynamic>[meterMap()];
      final meters = await Cdp.listMeters();
      expect(calls.last.method, 'cdp.listMeters');
      expect(meters.single.name, 'paywall');
    });

    test('incrementMeter returns new state', () async {
      responder = (_) => meterMap();
      final m = await Cdp.incrementMeter('paywall');
      expect(calls.last.method, 'cdp.incrementMeter');
      expect(calls.last.arguments, {'name': 'paywall'});
      expect(m?.count, 3);
    });

    test('incrementMeter null -> null', () async {
      responder = (_) => null;
      expect(await Cdp.incrementMeter('paywall'), isNull);
    });

    test('incrementMeter throws MeterNotFoundError on 404', () async {
      responder = (_) => throw PlatformException(
            code: 'METER_NOT_FOUND',
            message: 'meter_not_found: ghost',
            details: 'ghost',
          );
      expect(
        () => Cdp.incrementMeter('ghost'),
        throwsA(isA<MeterNotFoundError>()
            .having((e) => e.meterName, 'meterName', 'ghost')),
      );
    });

    test('incrementMeter rethrows other PlatformExceptions', () async {
      responder = (_) => throw PlatformException(code: 'ERROR', message: 'boom');
      expect(
        () => Cdp.incrementMeter('paywall'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
