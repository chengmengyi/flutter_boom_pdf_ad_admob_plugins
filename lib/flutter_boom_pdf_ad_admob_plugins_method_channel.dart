import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_boom_pdf_ad_admob_plugins_platform_interface.dart';

/// An implementation of [FlutterBoomPdfAdAdmobPluginsPlatform] that uses method channels.
class MethodChannelFlutterBoomPdfAdAdmobPlugins
    extends FlutterBoomPdfAdAdmobPluginsPlatform {
  static const EventChannel _nativeAdHeadlineEventChannel = EventChannel(
    'flutter_boom_pdf_ad_admob_plugins/native_ad_headline',
  );

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'flutter_boom_pdf_ad_admob_plugins',
  );

  @override
  Stream<Map<String, dynamic>> get nativeAdHeadlineStream =>
      _nativeAdHeadlineEventChannel.receiveBroadcastStream().map((event) {
        return Map<String, dynamic>.from(event as Map);
      });

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> configureSmallNativeAdLayout(String? layoutName) {
    return methodChannel.invokeMethod<void>(
      'configureSmallNativeAdLayout',
      <String, Object?>{'layoutName': layoutName},
    );
  }

  @override
  Future<bool> closeFullScreenAd() async {
    return await methodChannel.invokeMethod<bool>('closeFullScreenAd') ?? false;
  }

  @override
  Future<void> updateCloseableFullScreenAdActivityNames(
    Iterable<String> activityNames,
  ) {
    return methodChannel.invokeMethod<void>(
      'updateCloseableFullScreenAdActivityNames',
      <String, Object?>{'activityNames': activityNames.toList()},
    );
  }
}
