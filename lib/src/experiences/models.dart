enum ExperienceType {
  inline('inline'),
  flowcards('flowcards'),
  compass('compass'),
  adManager('adManager'),
  affiliationEnhancer('affiliationEnhancer'),
  conversions('conversions'),
  content('content'),
  experiments('experiments'),
  experimentation('experimentation'),
  recirculation('recirculation'),
  goalTracking('goalTracking'),
  ecommerce('ecommerce'),
  multimedia('multimedia'),
  piano('piano'),
  appBanner('appBanner'),
  unknown('unknown');

  const ExperienceType(this.value);
  final String value;

  static ExperienceType? fromKey(String? key) {
    if (key == null) return null;
    for (final t in ExperienceType.values) {
      if (t.value == key) return t;
    }
    return null;
  }
}

enum ExperienceFamily {
  twitter('twitterexperience'),
  facebook('facebookexperience'),
  youtube('youtubeexperience'),
  recommender('recommenderexperience'),
  telegram('telegramexperience'),
  gathering('gatheringexperience'),
  affiliate('affiliateexperience'),
  podcast('podcastexperience'),
  experimentation('experimentsexperience'),
  widget('widgetexperience'),
  marfeelPass('passexperience'),
  script('scriptexperience'),
  paywall('paywallexperience'),
  marfeelSocial('marfeelsocial'),
  unknown('unknown');

  const ExperienceFamily(this.value);
  final String value;

  static ExperienceFamily fromKey(String key) {
    for (final f in ExperienceFamily.values) {
      if (f.value == key) return f;
    }
    return ExperienceFamily.unknown;
  }
}

enum ExperienceContentType {
  textHTML('TextHTML'),
  json('Json'),
  amp('AMP'),
  widgetProvider('WidgetProvider'),
  adServer('AdServer'),
  container('Container'),
  unknown('Unknown');

  const ExperienceContentType(this.value);
  final String value;

  static ExperienceContentType fromKey(String key) {
    for (final c in ExperienceContentType.values) {
      if (c.value == key) return c;
    }
    return ExperienceContentType.unknown;
  }
}

class RecirculationLink {
  final String url;
  final int position;

  const RecirculationLink({required this.url, required this.position});

  Map<String, dynamic> toMap() => {'url': url, 'position': position};
}

class ExperienceSelector {
  final String selector;
  final String strategy;

  const ExperienceSelector({required this.selector, required this.strategy});

  factory ExperienceSelector.fromMap(Map<dynamic, dynamic> m) =>
      ExperienceSelector(
        selector: m['selector'] as String,
        strategy: m['strategy'] as String,
      );
}

class ExperienceFilter {
  final String key;
  final String operator;
  final List<String> values;

  const ExperienceFilter({
    required this.key,
    required this.operator,
    required this.values,
  });

  factory ExperienceFilter.fromMap(Map<dynamic, dynamic> m) => ExperienceFilter(
        key: m['key'] as String,
        operator: m['operator'] as String,
        values: (m['values'] as List).cast<String>(),
      );
}

class Experience {
  final String id;
  final String name;
  final ExperienceType type;
  final ExperienceFamily? family;
  final String? placement;
  final String? contentUrl;
  final ExperienceContentType contentType;
  final Map<String, dynamic>? features;
  final String? strategy;
  final List<ExperienceSelector>? selectors;
  final List<ExperienceFilter>? filters;
  final Map<String, dynamic> rawJson;
  String? resolvedContent;

  Experience({
    required this.id,
    required this.name,
    required this.type,
    required this.family,
    required this.placement,
    required this.contentUrl,
    required this.contentType,
    required this.features,
    required this.strategy,
    required this.selectors,
    required this.filters,
    required this.rawJson,
    this.resolvedContent,
  });

  factory Experience.fromMap(Map<dynamic, dynamic> m) {
    final selectorsRaw = m['selectors'] as List?;
    final filtersRaw = m['filters'] as List?;
    return Experience(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      type: ExperienceType.fromKey(m['type'] as String?) ??
          ExperienceType.unknown,
      family: m['family'] == null
          ? null
          : ExperienceFamily.fromKey(m['family'] as String),
      placement: m['placement'] as String?,
      contentUrl: m['contentUrl'] as String?,
      contentType: ExperienceContentType.fromKey(
          m['contentType'] as String? ?? 'Unknown'),
      features: (m['features'] as Map?)?.cast<String, dynamic>(),
      strategy: m['strategy'] as String?,
      selectors: selectorsRaw
          ?.cast<Map<dynamic, dynamic>>()
          .map(ExperienceSelector.fromMap)
          .toList(growable: false),
      filters: filtersRaw
          ?.cast<Map<dynamic, dynamic>>()
          .map(ExperienceFilter.fromMap)
          .toList(growable: false),
      rawJson: (m['rawJson'] as Map?)?.cast<String, dynamic>() ?? const {},
      resolvedContent: m['resolvedContent'] as String?,
    );
  }
}
