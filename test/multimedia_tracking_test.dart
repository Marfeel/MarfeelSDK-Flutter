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

  test('initializeItem sends correct arguments', () {
    MultimediaTracking.initializeItem(
      id: 'vid1',
      provider: 'youtube',
      providerId: 'abc123',
      type: MultimediaType.video,
    );
    expect(calls.last.method, 'initializeMultimediaItem');
    final args = calls.last.arguments as Map;
    expect(args['id'], 'vid1');
    expect(args['provider'], 'youtube');
    expect(args['providerId'], 'abc123');
    expect(args['type'], 'video');
  });

  test('initializeItem with metadata', () {
    MultimediaTracking.initializeItem(
      id: 'vid1',
      provider: 'youtube',
      providerId: 'abc123',
      type: MultimediaType.video,
      metadata: const MultimediaMetadata(title: 'My Video', duration: 120),
    );
    final args = calls.last.arguments as Map;
    final metadata = args['metadata'] as String;
    expect(metadata.contains('"title":"My Video"'), true);
    expect(metadata.contains('"duration":120'), true);
  });

  test('registerEvent sends correct arguments', () {
    MultimediaTracking.registerEvent(
      id: 'vid1',
      event: MultimediaEvent.play,
      eventTime: 30,
    );
    expect(calls.last.method, 'registerMultimediaEvent');
    final args = calls.last.arguments as Map;
    expect(args['id'], 'vid1');
    expect(args['event'], 'play');
    expect(args['eventTime'], 30);
  });
}
