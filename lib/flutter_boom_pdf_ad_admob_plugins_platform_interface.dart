import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_boom_pdf_ad_admob_plugins_method_channel.dart';

abstract class FlutterBoomPdfAdAdmobPluginsPlatform extends PlatformInterface {
  /// Constructs a FlutterBoomPdfAdAdmobPluginsPlatform.
  FlutterBoomPdfAdAdmobPluginsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBoomPdfAdAdmobPluginsPlatform _instance =
      MethodChannelFlutterBoomPdfAdAdmobPlugins();

  /// The default instance of [FlutterBoomPdfAdAdmobPluginsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBoomPdfAdAdmobPlugins].
  static FlutterBoomPdfAdAdmobPluginsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBoomPdfAdAdmobPluginsPlatform] when
  /// they register themselves.
  static set instance(FlutterBoomPdfAdAdmobPluginsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> configureSmallNativeAdLayout(String? layoutName) {
    throw UnimplementedError(
      'configureSmallNativeAdLayout() has not been implemented.',
    );
  }

  Future<bool> closeFullScreenAd() {
    throw UnimplementedError('closeFullScreenAd() has not been implemented.');
  }

  Future<void> updateCloseableFullScreenAdActivityNames(
    Iterable<String> activityNames,
  ) {
    throw UnimplementedError(
      'updateCloseableFullScreenAdActivityNames() has not been implemented.',
    );
  }
}
