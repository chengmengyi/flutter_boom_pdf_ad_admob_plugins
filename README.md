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
adapter. App-open, interstitial and native ads divide the queried estimated
revenue by `1000000` before caching it; other formats use `0` until a query API
is available.

On the first Core load, the adapter automatically completes UMP first. It only
requests AdMob ads when `canRequestAds` is true. Mobile Ads initialization is
then non-blocking: the adapter starts `MobileAds.instance.initialize()` and
immediately allows Core to load. Core emits `onNetworkInitialized('admob')`
and `onAdmobInitialized()` only after the Mobile Ads initialization Future
actually completes. Business code does not need to call `handleUmpConsent()`
or `initializeNetworks()` before loading.
