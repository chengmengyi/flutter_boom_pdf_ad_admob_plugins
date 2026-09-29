import 'dart:async';

import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_method_channel.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins_platform_interface.dart';
import 'package:flutter_boom_pdf_ad_core_plugins/flutter_boom_pdf_ad_core_plugins.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _queryRevenueChannel = MethodChannel('query_ad_revenue');
const _nativeHeadlineChannel =
    'flutter_boom_pdf_ad_admob_plugins/native_ad_headline';
const _methodCodec = StandardMethodCodec();

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

  test('native headline stream forwards token and headline', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final listening = Completer<void>();
    messenger.setMockMessageHandler(_nativeHeadlineChannel, (message) async {
      final call = _methodCodec.decodeMethodCall(message);
      if (call.method == 'listen' && !listening.isCompleted) {
        listening.complete();
      }
      return _methodCodec.encodeSuccessEnvelope(null);
    });
    final platform = MethodChannelFlutterBoomPdfAdAdmobPlugins();
    final eventFuture = platform.nativeAdHeadlineStream.first;
    await listening.future;

    await messenger.handlePlatformMessage(
      _nativeHeadlineChannel,
      _methodCodec.encodeSuccessEnvelope(<String, Object?>{
        'headline': 'Test Ad: Sample',
        'token': 'native-1',
        'isNextGenAdmob': false,
      }),
      (_) {},
    );

    expect(await eventFuture, <String, Object?>{
      'headline': 'Test Ad: Sample',
      'token': 'native-1',
      'isNextGenAdmob': false,
    });
    messenger.setMockMessageHandler(_nativeHeadlineChannel, null);
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
