# flutter_boom_pdf_ad_admob_plugins

AdMob adapter for `flutter_boom_pdf_ad_core_plugins`.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_boom_pdf_ad_admob_plugins/flutter_boom_pdf_ad_admob_plugins.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterBoomPdfAdAdmobPlugins.install();
  runApp(const App());
}
```

The adapter implements initialization, app-open, interstitial, rewarded,
banner and native loading, display callbacks, paid events, UMP and Ad
Inspector. Business code should use `FlutterBoomPdfAdCorePlugins.instance`
after installing the adapter.
