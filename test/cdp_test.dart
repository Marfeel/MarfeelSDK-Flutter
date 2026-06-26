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
    test('cdpDoIdentityLink sends type/value/isDeterministic', () {
      Cdp.cdpDoIdentityLink('registered_user_id', 'user@example.com',
          isDeterministic: true);
      expect(calls.last.method, 'cdp.doIdentityLink');
      expect(calls.last.arguments, {
        'type': 'registered_user_id',
        'value': 'user@example.com',
        'isDeterministic': true,
      });
    });

    test('cdpDoIdentityLink defaults isDeterministic to false', () {
      Cdp.cdpDoIdentityLink('email_hash', 'abc');
      expect((calls.last.arguments as Map)['isDeterministic'], false);
    });

    test('getCdpData parses masterId/rfv/cohorts', () async {
      responder = (_) => {
            'masterId': 'mid-1',
            'rfv': {'rfv': 42, 'r': 3, 'f': 5, 'v': 7},
            'cohorts': [101, 204],
          };
      final data = await Cdp.getCdpData();
      expect(calls.last.method, 'cdp.getData');
      expect(data.masterId, 'mid-1');
      expect(data.rfv?.rfv, 42);
      expect(data.rfv?.r, 3);
      expect(data.cohorts, [101, 204]);
    });

    test('getCdpData handles null/empty', () async {
      responder = (_) => null;
      final data = await Cdp.getCdpData();
      expect(data.masterId, isNull);
      expect(data.rfv, isNull);
      expect(data.cohorts, isEmpty);
    });

    test('getCdpData handles missing rfv', () async {
      responder = (_) => {'masterId': null, 'rfv': null, 'cohorts': <int>[]};
      final data = await Cdp.getCdpData();
      expect(data.rfv, isNull);
      expect(data.cohorts, isEmpty);
    });

    test('getCdpMasterId returns value', () async {
      responder = (_) => 'mid-2';
      expect(await Cdp.getCdpMasterId(), 'mid-2');
      expect(calls.last.method, 'cdp.getMasterId');
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
