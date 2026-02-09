import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

void main() {
  group('UserType', () {
    test('has correct numeric values', () {
      expect(UserType.anonymous.value, 1);
      expect(UserType.logged.value, 2);
      expect(UserType.paid.value, 3);
    });

    test('custom returns provided value', () {
      final custom = UserType.custom(42);
      expect(custom.value, 42);
    });
  });

  group('ConversionScope', () {
    test('has correct string values', () {
      expect(ConversionScope.user.value, 'user');
      expect(ConversionScope.session.value, 'session');
      expect(ConversionScope.page.value, 'page');
    });
  });

  group('MultimediaEvent', () {
    test('has correct string values', () {
      expect(MultimediaEvent.play.value, 'play');
      expect(MultimediaEvent.pause.value, 'pause');
      expect(MultimediaEvent.end.value, 'end');
      expect(MultimediaEvent.updateCurrentTime.value, 'updateCurrentTime');
      expect(MultimediaEvent.adPlay.value, 'adPlay');
      expect(MultimediaEvent.mute.value, 'mute');
      expect(MultimediaEvent.unmute.value, 'unmute');
      expect(MultimediaEvent.fullScreen.value, 'fullscreen');
      expect(MultimediaEvent.backScreen.value, 'backscreen');
      expect(MultimediaEvent.enterViewport.value, 'enterViewport');
      expect(MultimediaEvent.leaveViewport.value, 'leaveViewport');
    });
  });

  group('MultimediaType', () {
    test('has correct string values', () {
      expect(MultimediaType.audio.value, 'audio');
      expect(MultimediaType.video.value, 'video');
    });
  });

  group('RFV', () {
    test('fromJson parses correctly', () {
      final rfv = RFV.fromJson({'rfv': 1.5, 'r': 2.0, 'f': 3.0, 'v': 4.0});
      expect(rfv.rfv, 1.5);
      expect(rfv.r, 2.0);
      expect(rfv.f, 3.0);
      expect(rfv.v, 4.0);
    });
  });

  group('ConversionOptions', () {
    test('toMap includes only non-null fields', () {
      const opts =
          ConversionOptions(initiator: 'btn', scope: ConversionScope.page);
      final map = opts.toMap();
      expect(map['initiator'], 'btn');
      expect(map['scope'], 'page');
      expect(map.containsKey('id'), false);
      expect(map.containsKey('value'), false);
      expect(map.containsKey('meta'), false);
    });

    test('toMap includes all fields when set', () {
      const opts = ConversionOptions(
        initiator: 'btn',
        id: 'conv1',
        value: '10',
        meta: {'key': 'val'},
        scope: ConversionScope.user,
      );
      final map = opts.toMap();
      expect(map['initiator'], 'btn');
      expect(map['id'], 'conv1');
      expect(map['value'], '10');
      expect(map['meta'], {'key': 'val'});
      expect(map['scope'], 'user');
    });
  });

  group('MultimediaMetadata', () {
    test('toJson excludes null fields', () {
      const meta = MultimediaMetadata(title: 'My Video', duration: 120);
      final json = meta.toJson();
      expect(json['title'], 'My Video');
      expect(json['duration'], 120);
      expect(json.containsKey('isLive'), false);
      expect(json.containsKey('url'), false);
    });
  });
}
