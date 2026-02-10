enum ConversionScope {
  user('user'),
  session('session'),
  page('page');

  const ConversionScope(this.value);
  final String value;
}

enum MultimediaType {
  audio('audio'),
  video('video');

  const MultimediaType(this.value);
  final String value;
}

enum MultimediaEvent {
  play('play'),
  pause('pause'),
  end('end'),
  updateCurrentTime('updateCurrentTime'),
  adPlay('adPlay'),
  mute('mute'),
  unmute('unmute'),
  fullScreen('fullscreen'),
  backScreen('backscreen'),
  enterViewport('enterViewport'),
  leaveViewport('leaveViewport');

  const MultimediaEvent(this.value);
  final String value;
}

class UserType {
  final int value;
  const UserType._(this.value);

  static const anonymous = UserType._(1);
  static const logged = UserType._(2);
  static const paid = UserType._(3);
  factory UserType.custom(int value) => UserType._(value);
}

class ConversionOptions {
  final String? initiator;
  final String? id;
  final String? value;
  final Map<String, String>? meta;
  final ConversionScope? scope;

  const ConversionOptions({this.initiator, this.id, this.value, this.meta, this.scope});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (initiator != null) map['initiator'] = initiator;
    if (id != null) map['id'] = id;
    if (value != null) map['value'] = value;
    if (meta != null) map['meta'] = meta;
    if (scope != null) map['scope'] = scope!.value;
    return map;
  }
}

class MultimediaMetadata {
  final bool? isLive;
  final String? title;
  final String? description;
  final String? url;
  final String? thumbnail;
  final String? authors;
  final int? publishTime;
  final int? duration;

  const MultimediaMetadata({
    this.isLive,
    this.title,
    this.description,
    this.url,
    this.thumbnail,
    this.authors,
    this.publishTime,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (isLive != null) map['isLive'] = isLive;
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (url != null) map['url'] = url;
    if (thumbnail != null) map['thumbnail'] = thumbnail;
    if (authors != null) map['authors'] = authors;
    if (publishTime != null) map['publishTime'] = publishTime;
    if (duration != null) map['duration'] = duration;
    return map;
  }
}

class RFV {
  final double rfv;
  final double r;
  final double f;
  final double v;

  const RFV({required this.rfv, required this.r, required this.f, required this.v});

  factory RFV.fromJson(Map<String, dynamic> json) {
    return RFV(
      rfv: (json['rfv'] as num).toDouble(),
      r: (json['r'] as num).toDouble(),
      f: (json['f'] as num).toDouble(),
      v: (json['v'] as num).toDouble(),
    );
  }
}
