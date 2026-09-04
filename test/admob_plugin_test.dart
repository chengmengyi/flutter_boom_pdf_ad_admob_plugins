import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_method_channel.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('method channel is the default implementation', () {
    expect(
      FlutterBoomPdfAdAdmobPluginsPlatform.instance,
      isA<MethodChannelFlutterBoomPdfAdAdmobPlugins>(),
    );
  });

  test('public plugin forwards platform version', () async {
    FlutterBoomPdfAdAdmobPluginsPlatform.instance = _FakePlatform();
    expect(
      await FlutterBoomPdfAdAdmobPlugins().getPlatformVersion(),
      'test-platform',
    );
  });
}

class _FakePlatform extends FlutterBoomPdfAdAdmobPluginsPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getPlatformVersion() async => 'test-platform';

  @override
  Future<void> configureSmallNativeAdLayout(String? layoutName) async {}

  @override
  Future<bool> closeFullScreenAd() async => false;

  @override
  Future<void> updateCloseableFullScreenAdActivityNames(
    Iterable<String> activityNames,
  ) async {}
}
