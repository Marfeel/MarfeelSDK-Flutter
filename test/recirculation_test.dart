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
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MarfeelSdkChannel.channel, null);
  });

  test('trackEligible sends name + links', () {
    Recirculation.trackEligible(
      name: 'mod-a',
      links: const [
        RecirculationLink(url: 'https://a', position: 0),
        RecirculationLink(url: 'https://b', position: 1),
      ],
    );
    expect(calls.last.method, 'recirculation.trackEligible');
    final args = calls.last.arguments as Map;
    expect(args['name'], 'mod-a');
    expect(args['links'], [
      {'url': 'https://a', 'position': 0},
      {'url': 'https://b', 'position': 1},
    ]);
  });

  test('trackImpression sends links', () {
    Recirculation.trackImpression(
      name: 'mod-b',
      links: const [RecirculationLink(url: 'https://x', position: 5)],
    );
    expect(calls.last.method, 'recirculation.trackImpression');
    final args = calls.last.arguments as Map;
    expect(args['name'], 'mod-b');
    expect(args['links'], [
      {'url': 'https://x', 'position': 5},
    ]);
  });

  test('trackImpressionLink sends single link', () {
    Recirculation.trackImpressionLink(
      name: 'mod-c',
      link: const RecirculationLink(url: 'https://y', position: 2),
    );
    expect(calls.last.method, 'recirculation.trackImpressionLink');
    final args = calls.last.arguments as Map;
    expect(args['name'], 'mod-c');
    expect(args['link'], {'url': 'https://y', 'position': 2});
    expect(args.containsKey('links'), false);
  });

  test('trackClick sends single link', () {
    Recirculation.trackClick(
      name: 'mod-d',
      link: const RecirculationLink(url: 'https://z', position: 3),
    );
    expect(calls.last.method, 'recirculation.trackClick');
    final args = calls.last.arguments as Map;
    expect(args['name'], 'mod-d');
    expect(args['link'], {'url': 'https://z', 'position': 3});
  });

  test('RecirculationLink.toMap preserves sentinel position 255', () {
    const link = RecirculationLink(url: ' ', position: 255);
    expect(link.toMap(), {'url': ' ', 'position': 255});
  });
}
