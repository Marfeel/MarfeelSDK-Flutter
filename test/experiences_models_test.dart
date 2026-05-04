import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

void main() {
  group('ExperienceType', () {
    test('fromKey returns matching enum', () {
      expect(ExperienceType.fromKey('adManager'), ExperienceType.adManager);
      expect(ExperienceType.fromKey('recirculation'),
          ExperienceType.recirculation);
    });

    test('fromKey returns null for unknown key', () {
      expect(ExperienceType.fromKey('totallyMadeUp'), isNull);
    });

    test('fromKey returns null for null', () {
      expect(ExperienceType.fromKey(null), isNull);
    });

    test('value matches server keys', () {
      expect(ExperienceType.affiliationEnhancer.value, 'affiliationEnhancer');
      expect(ExperienceType.goalTracking.value, 'goalTracking');
    });
  });

  group('ExperienceFamily', () {
    test('fromKey returns matching enum', () {
      expect(ExperienceFamily.fromKey('recommenderexperience'),
          ExperienceFamily.recommender);
      expect(ExperienceFamily.fromKey('marfeelsocial'),
          ExperienceFamily.marfeelSocial);
    });

    test('fromKey returns unknown for unrecognised key', () {
      expect(ExperienceFamily.fromKey('mystery'), ExperienceFamily.unknown);
    });
  });

  group('ExperienceContentType', () {
    test('fromKey matches server keys', () {
      expect(ExperienceContentType.fromKey('TextHTML'),
          ExperienceContentType.textHTML);
      expect(ExperienceContentType.fromKey('Json'), ExperienceContentType.json);
      expect(ExperienceContentType.fromKey('AMP'), ExperienceContentType.amp);
      expect(ExperienceContentType.fromKey('WidgetProvider'),
          ExperienceContentType.widgetProvider);
    });

    test('fromKey returns unknown for unrecognised', () {
      expect(ExperienceContentType.fromKey('huh'),
          ExperienceContentType.unknown);
    });
  });

  group('Experience.fromMap', () {
    test('parses full payload', () {
      final exp = Experience.fromMap({
        'id': 'IL_x',
        'name': 'X',
        'type': 'inline',
        'family': 'twitterexperience',
        'placement': 'top',
        'contentUrl': 'https://c',
        'contentType': 'Json',
        'features': {'a': 1},
        'strategy': 'rotate',
        'selectors': [
          {'selector': '.ad', 'strategy': 'first'}
        ],
        'filters': [
          {
            'key': 'mrf_exp_g',
            'operator': 'eq',
            'values': ['v1', 'v2']
          }
        ],
        'rawJson': {'r': true},
      });
      expect(exp.id, 'IL_x');
      expect(exp.name, 'X');
      expect(exp.type, ExperienceType.inline);
      expect(exp.family, ExperienceFamily.twitter);
      expect(exp.placement, 'top');
      expect(exp.contentUrl, 'https://c');
      expect(exp.contentType, ExperienceContentType.json);
      expect(exp.features, {'a': 1});
      expect(exp.strategy, 'rotate');
      expect(exp.selectors, hasLength(1));
      expect(exp.filters, hasLength(1));
      expect(exp.filters!.first.values, ['v1', 'v2']);
      expect(exp.rawJson, {'r': true});
      expect(exp.resolvedContent, isNull);
    });

    test('parses minimal payload (defaults applied)', () {
      final exp = Experience.fromMap({
        'id': 'X',
        'name': 'Y',
        'type': 'compass',
        'contentType': 'Unknown',
      });
      expect(exp.id, 'X');
      expect(exp.family, isNull);
      expect(exp.placement, isNull);
      expect(exp.contentUrl, isNull);
      expect(exp.features, isNull);
      expect(exp.selectors, isNull);
      expect(exp.filters, isNull);
      expect(exp.rawJson, isEmpty);
    });

    test('unknown family string maps to unknown enum', () {
      final exp = Experience.fromMap({
        'id': 'X',
        'name': 'Y',
        'type': 'inline',
        'family': 'somethingNew',
        'contentType': 'Json',
      });
      expect(exp.family, ExperienceFamily.unknown);
    });

    test('unknown type string maps to unknown enum', () {
      final exp = Experience.fromMap({
        'id': 'X',
        'name': 'Y',
        'type': 'somethingNew',
        'contentType': 'Json',
      });
      expect(exp.type, ExperienceType.unknown);
    });
  });

  group('RecirculationLink', () {
    test('toMap round-trips fields', () {
      const link = RecirculationLink(url: 'https://x', position: 7);
      expect(link.toMap(), {'url': 'https://x', 'position': 7});
    });
  });

  group('ExperienceFilter / ExperienceSelector', () {
    test('ExperienceFilter.fromMap', () {
      final f = ExperienceFilter.fromMap({
        'key': 'k',
        'operator': 'eq',
        'values': ['a', 'b'],
      });
      expect(f.key, 'k');
      expect(f.operator, 'eq');
      expect(f.values, ['a', 'b']);
    });

    test('ExperienceSelector.fromMap', () {
      final s = ExperienceSelector.fromMap({
        'selector': '.foo',
        'strategy': 'all',
      });
      expect(s.selector, '.foo');
      expect(s.strategy, 'all');
    });
  });
}
