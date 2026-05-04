import 'package:flutter/services.dart';

import '../method_channel.dart';
import 'models.dart';

class Experiences {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  Experiences._();

  static void addTargeting(String key, String value) {
    _channel.invokeMethod('experiences.addTargeting', {
      'key': key,
      'value': value,
    });
  }

  static Future<List<Experience>> fetchExperiences({
    ExperienceType? filterByType,
    ExperienceFamily? filterByFamily,
    bool resolve = false,
    String? url,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'experiences.fetch',
      {
        'filterByType': filterByType?.value,
        'filterByFamily': filterByFamily?.value,
        'resolve': resolve,
        'url': url,
      },
    );
    if (result == null) return const [];
    return result
        .cast<Map<dynamic, dynamic>>()
        .map(Experience.fromMap)
        .toList(growable: false);
  }

  static void trackEligible({
    required Experience experience,
    required List<RecirculationLink> links,
  }) {
    _channel.invokeMethod('experiences.trackEligible', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpression({
    required Experience experience,
    required List<RecirculationLink> links,
  }) {
    _channel.invokeMethod('experiences.trackImpression', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'links': links.map((l) => l.toMap()).toList(),
    });
  }

  static void trackImpressionLink({
    required Experience experience,
    required RecirculationLink link,
  }) {
    _channel.invokeMethod('experiences.trackImpressionLink', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'link': link.toMap(),
    });
  }

  static void trackClick({
    required Experience experience,
    required RecirculationLink link,
  }) {
    _channel.invokeMethod('experiences.trackClick', {
      'experienceId': experience.id,
      'experienceName': experience.name,
      'link': link.toMap(),
    });
  }

  static void trackClose(Experience experience) {
    _channel.invokeMethod('experiences.trackClose', {
      'experienceId': experience.id,
    });
  }

  static Future<String?> resolveExperience(Experience experience) async {
    final content = await _channel.invokeMethod<String>(
      'experiences.resolve',
      {'experienceId': experience.id},
    );
    experience.resolvedContent = content;
    return content;
  }

  static void clearFrequencyCaps() {
    _channel.invokeMethod('experiences.clearFrequencyCaps');
  }

  static Future<Map<String, int>> getFrequencyCapCounts(
      String experienceId) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'experiences.getFrequencyCapCounts',
      {'experienceId': experienceId},
    );
    if (result == null) return const {};
    return result.map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    );
  }

  static Future<Map<String, List<String>>> getFrequencyCapConfig() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'experiences.getFrequencyCapConfig',
    );
    if (result == null) return const {};
    return result.map(
      (k, v) => MapEntry(k as String, (v as List).cast<String>()),
    );
  }

  static void clearReadEditorials() {
    _channel.invokeMethod('experiences.clearReadEditorials');
  }

  static Future<List<String>> getReadEditorials() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'experiences.getReadEditorials',
    );
    if (result == null) return const [];
    return result.cast<String>();
  }

  static Future<Map<String, String>> getExperimentAssignments() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'experiences.getExperimentAssignments',
    );
    if (result == null) return const {};
    return result.map((k, v) => MapEntry(k as String, v as String));
  }

  static void setExperimentAssignment({
    required String groupId,
    required String variantId,
  }) {
    _channel.invokeMethod('experiences.setExperimentAssignment', {
      'groupId': groupId,
      'variantId': variantId,
    });
  }

  static void clearExperimentAssignments() {
    _channel.invokeMethod('experiences.clearExperimentAssignments');
  }
}
