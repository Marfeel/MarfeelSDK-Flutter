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

  Experience makeExperience({String id = 'exp-1', String name = 'Exp 1'}) {
    return Experience(
      id: id,
      name: name,
      type: ExperienceType.adManager,
      family: ExperienceFamily.recommender,
      placement: 'top',
      contentUrl: null,
      contentType: ExperienceContentType.textHTML,
      features: null,
      strategy: null,
      selectors: null,
      filters: null,
      rawJson: const {},
    );
  }

  test('addTargeting sends key + value', () {
    Experiences.addTargeting('country', 'ES');
    expect(calls.last.method, 'experiences.addTargeting');
    expect(calls.last.arguments, {'key': 'country', 'value': 'ES'});
  });

  test('fetchExperiences with no filters', () async {
    responder = (_) => <dynamic>[];
    final result = await Experiences.fetchExperiences();
    expect(calls.last.method, 'experiences.fetch');
    final args = calls.last.arguments as Map;
    expect(args['filterByType'], null);
    expect(args['filterByFamily'], null);
    expect(args['resolve'], false);
    expect(args['url'], null);
    expect(result, isEmpty);
  });

  test('fetchExperiences with filters sends string values', () async {
    responder = (_) => <dynamic>[];
    await Experiences.fetchExperiences(
      filterByType: ExperienceType.adManager,
      filterByFamily: ExperienceFamily.recommender,
      resolve: true,
      url: 'https://page',
    );
    final args = calls.last.arguments as Map;
    expect(args['filterByType'], 'adManager');
    expect(args['filterByFamily'], 'recommenderexperience');
    expect(args['resolve'], true);
    expect(args['url'], 'https://page');
  });

  test('fetchExperiences returns empty list when channel returns null',
      () async {
    responder = (_) => null;
    final result = await Experiences.fetchExperiences();
    expect(result, isEmpty);
  });

  test('fetchExperiences parses experience payload', () async {
    responder = (_) => [
          {
            'id': 'IL_a',
            'name': 'My Exp',
            'type': 'adManager',
            'family': 'recommenderexperience',
            'placement': 'top',
            'contentUrl': 'https://content',
            'contentType': 'TextHTML',
            'features': {'k': 'v'},
            'strategy': 'random',
            'selectors': [
              {'selector': 'css', 'strategy': 'first'}
            ],
            'filters': [
              {
                'key': 'mrf_exp_g1',
                'operator': 'eq',
                'values': ['v1']
              }
            ],
            'rawJson': {'foo': 'bar'},
          }
        ];
    final result = await Experiences.fetchExperiences();
    expect(result, hasLength(1));
    final exp = result.first;
    expect(exp.id, 'IL_a');
    expect(exp.name, 'My Exp');
    expect(exp.type, ExperienceType.adManager);
    expect(exp.family, ExperienceFamily.recommender);
    expect(exp.placement, 'top');
    expect(exp.contentUrl, 'https://content');
    expect(exp.contentType, ExperienceContentType.textHTML);
    expect(exp.features, {'k': 'v'});
    expect(exp.strategy, 'random');
    expect(exp.selectors, hasLength(1));
    expect(exp.selectors!.first.selector, 'css');
    expect(exp.filters, hasLength(1));
    expect(exp.filters!.first.key, 'mrf_exp_g1');
    expect(exp.filters!.first.operator, 'eq');
    expect(exp.filters!.first.values, ['v1']);
    expect(exp.rawJson, {'foo': 'bar'});
    expect(exp.resolvedContent, isNull);
  });

  test('fetchExperiences accepts experience without family', () async {
    responder = (_) => [
          {
            'id': 'X',
            'name': 'No Family',
            'type': 'inline',
            'contentType': 'Json',
          }
        ];
    final result = await Experiences.fetchExperiences();
    expect(result.first.family, isNull);
  });

  test('trackImpression sends id, name, links', () {
    Experiences.trackImpression(
      experience: makeExperience(),
      links: const [RecirculationLink(url: 'https://a', position: 0)],
    );
    expect(calls.last.method, 'experiences.trackImpression');
    final args = calls.last.arguments as Map;
    expect(args['experienceId'], 'exp-1');
    expect(args['experienceName'], 'Exp 1');
    expect(args['links'], [
      {'url': 'https://a', 'position': 0},
    ]);
  });

  test('trackImpressionLink sends single link', () {
    Experiences.trackImpressionLink(
      experience: makeExperience(),
      link: const RecirculationLink(url: 'https://l', position: 4),
    );
    expect(calls.last.method, 'experiences.trackImpressionLink');
    final args = calls.last.arguments as Map;
    expect(args['link'], {'url': 'https://l', 'position': 4});
    expect(args.containsKey('links'), false);
  });

  test('trackEligible sends id, name, links', () {
    Experiences.trackEligible(
      experience: makeExperience(),
      links: const [RecirculationLink(url: 'https://a', position: 0)],
    );
    expect(calls.last.method, 'experiences.trackEligible');
  });

  test('trackClick sends single link', () {
    Experiences.trackClick(
      experience: makeExperience(),
      link: const RecirculationLink(url: 'https://c', position: 1),
    );
    expect(calls.last.method, 'experiences.trackClick');
    final args = calls.last.arguments as Map;
    expect(args['link'], {'url': 'https://c', 'position': 1});
  });

  test('trackClose sends only experienceId', () {
    Experiences.trackClose(makeExperience(id: 'exp-2'));
    expect(calls.last.method, 'experiences.trackClose');
    expect(calls.last.arguments, {'experienceId': 'exp-2'});
  });

  test('resolveExperience updates resolvedContent', () async {
    responder = (_) => '<html>hi</html>';
    final exp = makeExperience();
    final content = await Experiences.resolveExperience(exp);
    expect(content, '<html>hi</html>');
    expect(exp.resolvedContent, '<html>hi</html>');
    expect(calls.last.method, 'experiences.resolve');
    expect(calls.last.arguments, {'experienceId': 'exp-1'});
  });

  test('getFrequencyCapCounts coerces ints', () async {
    responder = (_) => <String, dynamic>{'l': 5, 'cl': 1};
    final counts = await Experiences.getFrequencyCapCounts('exp-1');
    expect(counts, {'l': 5, 'cl': 1});
  });

  test('getFrequencyCapCounts coerces longs (Android sends 64-bit)', () async {
    responder = (_) => <String, dynamic>{'l': 9999999999};
    final counts = await Experiences.getFrequencyCapCounts('exp-1');
    expect(counts['l'], 9999999999);
  });

  test('getFrequencyCapConfig parses Map<String, List<String>>', () async {
    responder = (_) => <String, dynamic>{
          'IL_a': <String>['l', 'd'],
          'IL_b': <String>['m'],
        };
    final config = await Experiences.getFrequencyCapConfig();
    expect(config['IL_a'], ['l', 'd']);
    expect(config['IL_b'], ['m']);
  });

  test('getReadEditorials parses list of strings', () async {
    responder = (_) => <String>['120', '130', '135'];
    final ids = await Experiences.getReadEditorials();
    expect(ids, ['120', '130', '135']);
  });

  test('getExperimentAssignments parses Map<String,String>', () async {
    responder = (_) => <String, dynamic>{'g1': 'v1', 'g2': 'v2'};
    final assignments = await Experiences.getExperimentAssignments();
    expect(assignments, {'g1': 'v1', 'g2': 'v2'});
  });

  test('setExperimentAssignment sends groupId + variantId', () {
    Experiences.setExperimentAssignment(groupId: 'g1', variantId: 'v1');
    expect(calls.last.method, 'experiences.setExperimentAssignment');
    expect(calls.last.arguments, {'groupId': 'g1', 'variantId': 'v1'});
  });

  test('clear* methods invoke without arguments', () {
    Experiences.clearFrequencyCaps();
    expect(calls.last.method, 'experiences.clearFrequencyCaps');
    Experiences.clearReadEditorials();
    expect(calls.last.method, 'experiences.clearReadEditorials');
    Experiences.clearExperimentAssignments();
    expect(calls.last.method, 'experiences.clearExperimentAssignments');
  });
}
