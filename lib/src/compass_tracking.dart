import 'dart:convert';

import 'package:flutter/services.dart';

import 'method_channel.dart';
import 'types.dart';

class CompassTracking {
  static const MethodChannel _channel = MarfeelSdkChannel.channel;

  CompassTracking._();

  static void initialize(String accountId, {int? pageTechnology}) {
    _channel.invokeMethod('initialize', {
      'accountId': accountId,
      'pageTechnology': pageTechnology,
    });
  }

  static void trackNewPage(String url, {int? scrollViewId, String? rs}) {
    _channel.invokeMethod('trackNewPage', {
      'url': url,
      'scrollViewId': scrollViewId,
      'rs': rs,
    });
  }

  static void trackScreen(String screen, {int? scrollViewId, String? rs}) {
    _channel.invokeMethod('trackScreen', {
      'screen': screen,
      'scrollViewId': scrollViewId,
      'rs': rs,
    });
  }

  static void stopTracking() {
    _channel.invokeMethod('stopTracking');
  }

  static void setLandingPage(String landingPage) {
    _channel.invokeMethod('setLandingPage', {'landingPage': landingPage});
  }

  static void setSiteUserId(String userId) {
    _channel.invokeMethod('setSiteUserId', {'userId': userId});
  }

  static Future<String> getUserId() async {
    final result = await _channel.invokeMethod<String>('getUserId');
    return result!;
  }

  static void setUserType(UserType userType) {
    _channel.invokeMethod('setUserType', {'userType': userType.value});
  }

  static Future<RFV?> getRFV() async {
    final result = await _channel.invokeMethod<String>('getRFV');
    if (result == null) return null;
    return RFV.fromJson(json.decode(result) as Map<String, dynamic>);
  }

  static void setPageVar(String name, String value) {
    _channel.invokeMethod('setPageVar', {'name': name, 'value': value});
  }

  static void setPageMetric(String name, int value) {
    _channel.invokeMethod('setPageMetric', {'name': name, 'value': value});
  }

  static void setSessionVar(String name, String value) {
    _channel.invokeMethod('setSessionVar', {'name': name, 'value': value});
  }

  static void setUserVar(String name, String value) {
    _channel.invokeMethod('setUserVar', {'name': name, 'value': value});
  }

  static void addUserSegment(String segment) {
    _channel.invokeMethod('addUserSegment', {'segment': segment});
  }

  static void setUserSegments(List<String> segments) {
    _channel.invokeMethod('setUserSegments', {'segments': segments});
  }

  static void removeUserSegment(String segment) {
    _channel.invokeMethod('removeUserSegment', {'segment': segment});
  }

  static void clearUserSegments() {
    _channel.invokeMethod('clearUserSegments');
  }

  static void trackConversion(String conversion, {ConversionOptions? options}) {
    final args = <String, dynamic>{'conversion': conversion};
    if (options != null) {
      args.addAll(options.toMap());
    }
    _channel.invokeMethod('trackConversion', args);
  }

  static void setConsent(bool hasConsent) {
    _channel.invokeMethod('setConsent', {'hasConsent': hasConsent});
  }

  static void updateScrollPercentage(int percentage) {
    _channel.invokeMethod(
        'updateScrollPercentage', {'percentage': percentage});
  }
}
