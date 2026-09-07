import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_method_channel.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_platform_interface.dart';
import 'package:flutter_boom_pdf_ad_core_plugins/flutter_boom_pdf_ad_core_plugins.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _queryRevenueChannel = MethodChannel('query_ad_revenue');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_queryRevenueChannel, null);
    await FlutterBoomPdfAdCorePlugins.instance.dispose();
  });

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

  test(
    'install initializes query revenue before registering adapter',
    () async {
      var initialized = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_queryRevenueChannel, (call) async {
            expect(call.method, 'initConfig');
            expect(call.arguments['libName'], 'revenue-lib');
            initialized = true;
            return null;
          });

      await FlutterBoomPdfAdAdmobPlugins.install(
        queryAdRevenueConfig: const QueryAdRevenueConfig(
          enableRevenue: true,
          openKeyList: <String>['open'],
          intKeyList: <String>['int'],
          nativeKeyList: <String>['native'],
          libName: 'revenue-lib',
        ),
      );

      expect(initialized, isTrue);
      expect(
        FlutterBoomPdfAdCorePlugins.instance.registeredNetworkIds,
        contains('admob'),
      );
    },
  );
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
