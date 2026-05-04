import 'package:flutter/services.dart';

import '../method_channel.dart';
import 'models.dart';

class Recirculation {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  Recirculation._();

  static void trackEligible({
    required String name,
    required List<RecirculationLink> links,
  }) {
    _channel.invokeMethod('recirculation.trackEligible', {
      'name': name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpression({
    required String name,
    required List<RecirculationLink> links,
  }) {
    _channel.invokeMethod('recirculation.trackImpression', {
      'name': name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpressionLink({
    required String name,
    required RecirculationLink link,
  }) {
    _channel.invokeMethod('recirculation.trackImpressionLink', {
      'name': name,
      'link': link.toMap(),
    });
  }

  static void trackClick({
    required String name,
    required RecirculationLink link,
  }) {
    _channel.invokeMethod('recirculation.trackClick', {
      'name': name,
      'link': link.toMap(),
    });
  }
}
