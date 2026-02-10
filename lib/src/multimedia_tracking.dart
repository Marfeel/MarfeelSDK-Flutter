import 'dart:convert';

import 'package:flutter/services.dart';

import 'method_channel.dart';
import 'types.dart';

class MultimediaTracking {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  MultimediaTracking._();

  static void initializeItem({
    required String id,
    required String provider,
    required String providerId,
    required MultimediaType type,
    MultimediaMetadata? metadata,
  }) {
    _channel.invokeMethod('initializeMultimediaItem', {
      'id': id,
      'provider': provider,
      'providerId': providerId,
      'type': type.value,
      'metadata': json.encode(metadata?.toJson() ?? {}),
    });
  }

  static void registerEvent({
    required String id,
    required MultimediaEvent event,
    required int eventTime,
  }) {
    _channel.invokeMethod('registerMultimediaEvent', {
      'id': id,
      'event': event.value,
      'eventTime': eventTime,
    });
  }
}
