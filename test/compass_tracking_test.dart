import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';
import 'package:marfeel_sdk/src/method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, (call) async {
      calls.add(call);
      if (call.method == 'getUserId') return 'test-user-id';
      if (call.method == 'getRFV') {
        return '{"rfv":1.0,"r":2.0,"f":3.0,"v":4.0}';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, null);
  });

  test('initialize sends correct arguments', () {
    CompassTracking.initialize('1659', pageTechnology: 105);
    expect(calls.last.method, 'initialize');
    expect(calls.last.arguments, {'accountId': '1659', 'pageTechnology': 105});
  });

  test('initialize without pageTechnology', () {
    CompassTracking.initialize('1659');
    expect(
        calls.last.arguments, {'accountId': '1659', 'pageTechnology': null});
  });

  test('trackNewPage sends url and rs', () {
    CompassTracking.trackNewPage('http://example.com', rs: 'source1');
    expect(calls.last.method, 'trackNewPage');
    expect(calls.last.arguments['url'], 'http://example.com');
    expect(calls.last.arguments['rs'], 'source1');
  });

  test('trackScreen sends screen name', () {
    CompassTracking.trackScreen('home');
    expect(calls.last.method, 'trackScreen');
    expect(calls.last.arguments['screen'], 'home');
  });

  test('stopTracking', () {
    CompassTracking.stopTracking();
    expect(calls.last.method, 'stopTracking');
  });

  test('setUserType anonymous', () {
    CompassTracking.setUserType(UserType.anonymous);
    expect(calls.last.arguments, {'userType': 1});
  });

  test('setUserType custom', () {
    CompassTracking.setUserType(UserType.custom(42));
    expect(calls.last.arguments, {'userType': 42});
  });

  test('getUserId returns value', () async {
    final id = await CompassTracking.getUserId();
    expect(id, 'test-user-id');
  });

  test('getRFV parses json', () async {
    final rfv = await CompassTracking.getRFV();
    expect(rfv?.rfv, 1.0);
    expect(rfv?.r, 2.0);
  });

  test('getRFV returns null when native returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, (call) async {
      calls.add(call);
      return null;
    });
    final rfv = await CompassTracking.getRFV();
    expect(rfv, isNull);
  });

  test('trackConversion simple', () {
    CompassTracking.trackConversion('purchase');
    expect(calls.last.method, 'trackConversion');
    expect(calls.last.arguments['conversion'], 'purchase');
  });

  test('trackConversion with options', () {
    CompassTracking.trackConversion(
      'purchase',
      options: const ConversionOptions(
        initiator: 'btn',
        id: 'c1',
        value: '10',
        meta: {'k': 'v'},
        scope: ConversionScope.page,
      ),
    );
    final args = calls.last.arguments as Map;
    expect(args['conversion'], 'purchase');
    expect(args['initiator'], 'btn');
    expect(args['id'], 'c1');
    expect(args['value'], '10');
    expect(args['meta'], {'k': 'v'});
    expect(args['scope'], 'page');
  });

  test('setPageVar', () {
    CompassTracking.setPageVar('key', 'val');
    expect(calls.last.arguments, {'name': 'key', 'value': 'val'});
  });

  test('setPageMetric', () {
    CompassTracking.setPageMetric('words', 850);
    expect(calls.last.arguments, {'name': 'words', 'value': 850});
  });

  test('setUserSegments', () {
    CompassTracking.setUserSegments(['a', 'b']);
    expect(calls.last.arguments, {
      'segments': ['a', 'b']
    });
  });

  test('setConsent', () {
    CompassTracking.setConsent(true);
    expect(calls.last.arguments, {'hasConsent': true});
  });
}
