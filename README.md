# flutter_boom_pdf_ad_admob_plugins

AdMob adapter for `flutter_boom_pdf_ad_core_plugins`.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBoomPdfAdAdmobPlugins.install(
    queryAdRevenueConfig: const QueryAdRevenueConfig(
      enableRevenue: true,
      openKeyList: <String>['YOUR_OPEN_REVENUE_KEY'],
      intKeyList: <String>['YOUR_INTERSTITIAL_REVENUE_KEY'],
      nativeKeyList: <String>['YOUR_NATIVE_REVENUE_KEY'],
      libName: 'YOUR_SO_LIBRARY_NAME_WITHOUT_LIB_PREFIX',
    ),
  );
  runApp(const App());
}
```

The adapter implements initialization, app-open, interstitial, rewarded,
banner and native loading, display callbacks, paid events, UMP and Ad
Inspector. Business code should use `FlutterBoomPdfAdCorePlugins.instance`
after installing the adapter.

`install` initializes `query_ad_revenue` before registering the AdMob
adapter. App-open, interstitial and native ads save the queried estimated
revenue in micros; other formats use `0` until a query API is available.
