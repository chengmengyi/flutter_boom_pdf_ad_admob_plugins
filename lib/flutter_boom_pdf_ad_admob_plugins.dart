import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_boom_pdf_ad_core_plugins/flutter_boom_pdf_ad_core_plugins.dart'
    as core;
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as gma_internal;
import 'package:query_ad_revenue/query_ad_revenue.dart';

import 'flutter_boom_pdf_ad_admob_plugins_platform_interface.dart';

export 'package:query_ad_revenue/query_ad_revenue.dart'
    show QueryAdRevenueConfig;

class FlutterBoomPdfAdAdmobPlugins {
  FlutterBoomPdfAdAdmobPlugins();

  static final FlutterBoomPdfAdAdmobAdapter adapter =
      FlutterBoomPdfAdAdmobAdapter();

  static Future<void> install({
    required QueryAdRevenueConfig queryAdRevenueConfig,
    core.FlutterBoomPdfAdCorePlugins? into,
  }) async {
    await QueryAdRevenue.instance.initConfig(config: queryAdRevenueConfig);
    (into ?? core.FlutterBoomPdfAdCorePlugins.instance).registerAdapter(
      adapter,
    );
  }

  Future<String?> getPlatformVersion() =>
      FlutterBoomPdfAdAdmobPluginsPlatform.instance.getPlatformVersion();
}

class FlutterBoomPdfAdAdmobAdapter extends core.FlutterBoomPdfAdAdapter {
  core.AdNetworkConfiguration _configuration =
      const core.AdNetworkConfiguration();

  @override
  String get networkId => 'admob';

  @override
  Future<void> configure(core.AdNetworkConfiguration configuration) async {
    _configuration = configuration;
    await FlutterBoomPdfAdAdmobPluginsPlatform.instance
        .configureSmallNativeAdLayout(configuration.smallNativeAdLayoutName);
  }

  @override
  Future<void> initialize() async {
    await gma.MobileAds.instance.initialize();
  }

  @override
  bool supports(core.AdType adType) => true;

  @override
  Future<core.AdLoadResult> load(core.AdLoadRequest request) {
    final adId = request.info.adId;
    final adType = request.info.parsedAdType;
    if (adId == null || adId.isEmpty || adType == null) {
      return Future.value(
        const core.AdLoadResult.failure(
          'invalid-ad-config',
          adNetwork: 'Admob',
        ),
      );
    }
    switch (adType) {
      case core.AdType.appOpen:
        return _loadAppOpen(adId, request);
      case core.AdType.interstitial:
        return _loadInterstitial(adId, request);
      case core.AdType.rewarded:
        return _loadRewarded(adId, request);
      case core.AdType.banner:
        return _loadBanner(adId, request);
      case core.AdType.native:
        return _loadNative(adId, request);
    }
  }

  gma.AdRequest _adRequest(core.AdLoadRequest request) {
    return request.networkOptions['defaultAdRequest'] as gma.AdRequest? ??
        _configuration.options['defaultAdRequest'] as gma.AdRequest? ??
        const gma.AdRequest();
  }

  Future<core.AdLoadResult> _loadAppOpen(
    String adId,
    core.AdLoadRequest request,
  ) async {
    final completer = Completer<core.AdLoadResult>();
    try {
      await gma.AppOpenAd.load(
        adUnitId: adId,
        request: _adRequest(request),
        adLoadCallback: gma.AppOpenAdLoadCallback(
          onAdLoaded: (ad) =>
              _completeLoaded(completer, ad, core.AdType.appOpen),
          onAdFailedToLoad: (error) => _completeFailure(completer, error),
        ),
      );
    } catch (error) {
      _completeException(completer, error);
    }
    return completer.future;
  }

  Future<core.AdLoadResult> _loadInterstitial(
    String adId,
    core.AdLoadRequest request,
  ) async {
    final completer = Completer<core.AdLoadResult>();
    try {
      await gma.InterstitialAd.load(
        adUnitId: adId,
        request: _adRequest(request),
        adLoadCallback: gma.InterstitialAdLoadCallback(
          onAdLoaded: (ad) =>
              _completeLoaded(completer, ad, core.AdType.interstitial),
          onAdFailedToLoad: (error) => _completeFailure(completer, error),
        ),
      );
    } catch (error) {
      _completeException(completer, error);
    }
    return completer.future;
  }

  Future<core.AdLoadResult> _loadRewarded(
    String adId,
    core.AdLoadRequest request,
  ) async {
    final completer = Completer<core.AdLoadResult>();
    try {
      await gma.RewardedAd.load(
        adUnitId: adId,
        request: _adRequest(request),
        rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
          onAdLoaded: (ad) =>
              _completeLoaded(completer, ad, core.AdType.rewarded),
          onAdFailedToLoad: (error) => _completeFailure(completer, error),
        ),
      );
    } catch (error) {
      _completeException(completer, error);
    }
    return completer.future;
  }

  Future<core.AdLoadResult> _loadBanner(
    String adId,
    core.AdLoadRequest request,
  ) async {
    final completer = Completer<core.AdLoadResult>();
    final events = _AdmobEventEmitter();
    final configuredSize =
        request.networkOptions['bannerSize'] as gma.AdSize? ??
        _configuration.options['bannerSize'] as gma.AdSize? ??
        gma.AdSize.banner;
    final ad = gma.BannerAd(
      size: request.largeBanner ? gma.AdSize.largeBanner : configuredSize,
      adUnitId: adId,
      listener: gma.BannerAdListener(
        onAdLoaded: (ad) =>
            _completeLoaded(completer, ad, core.AdType.banner, events: events),
        onAdFailedToLoad: (ad, error) async {
          final network = _networkFor(ad);
          await ad.dispose();
          events.close();
          _completeFailure(completer, error, network: network);
        },
        onAdClicked: (_) => events.clicked(),
        onAdImpression: (_) => events.impression(),
        onPaidEvent: events.paid,
      ),
      request: _bannerRequest(request),
    );
    try {
      await ad.load();
    } catch (error) {
      await ad.dispose();
      events.close();
      _completeException(completer, error);
    }
    return completer.future;
  }

  gma.AdRequest _bannerRequest(core.AdLoadRequest request) {
    final base = _adRequest(request);
    final direction = request.collapsibleBannerDirection;
    if (direction == null || direction.isEmpty) return base;
    return gma.AdRequest(
      keywords: base.keywords,
      contentUrl: base.contentUrl,
      neighboringContentUrls: base.neighboringContentUrls,
      nonPersonalizedAds: base.nonPersonalizedAds,
      httpTimeoutMillis: base.httpTimeoutMillis,
      extras: <String, String>{...?base.extras, 'collapsible': direction},
      mediationExtras: base.mediationExtras,
    );
  }

  Future<core.AdLoadResult> _loadNative(
    String adId,
    core.AdLoadRequest request,
  ) async {
    final completer = Completer<core.AdLoadResult>();
    final events = _AdmobEventEmitter();
    final factoryId = request.interstitialLikeNative
        ? 'full_screen_native'
        : (_configuration.smallNativeAdLayoutName != null &&
              request.smallTemplateNative)
        ? 'guide_compact_native'
        : null;
    final configuredStyle =
        request.networkOptions['nativeTemplateStyle']
            as gma.NativeTemplateStyle? ??
        _configuration.options['nativeTemplateStyle']
            as gma.NativeTemplateStyle?;
    final ad = gma.NativeAd(
      adUnitId: adId,
      factoryId: factoryId,
      listener: gma.NativeAdListener(
        onAdLoaded: (ad) =>
            _completeLoaded(completer, ad, core.AdType.native, events: events),
        onAdFailedToLoad: (ad, error) async {
          final network = _networkFor(ad);
          await ad.dispose();
          events.close();
          _completeFailure(completer, error, network: network);
        },
        onAdClicked: (_) => events.clicked(),
        onAdImpression: (_) => events.impression(),
        onPaidEvent: events.paid,
      ),
      request: _adRequest(request),
      nativeAdOptions: gma.NativeAdOptions(
        adChoicesPlacement: _adChoicesPlacement(),
        mediaAspectRatio: request.interstitialLikeNative
            ? gma.MediaAspectRatio.portrait
            : gma.MediaAspectRatio.unknown,
        videoOptions: gma.VideoOptions(startMuted: true),
      ),
      nativeTemplateStyle: factoryId == null
          ? configuredStyle ??
                gma.NativeTemplateStyle(
                  templateType: request.smallTemplateNative
                      ? gma.TemplateType.small
                      : gma.TemplateType.medium,
                )
          : null,
    );
    try {
      await ad.load();
    } catch (error) {
      await ad.dispose();
      events.close();
      _completeException(completer, error);
    }
    return completer.future;
  }

  gma.AdChoicesPlacement _adChoicesPlacement() {
    switch (_configuration.nativeAdChoicesPlacement) {
      case core.AdChoicesPlacement.topLeftCorner:
        return gma.AdChoicesPlacement.topLeftCorner;
      case core.AdChoicesPlacement.topRightCorner:
        return gma.AdChoicesPlacement.topRightCorner;
      case core.AdChoicesPlacement.bottomLeftCorner:
        return gma.AdChoicesPlacement.bottomLeftCorner;
      case core.AdChoicesPlacement.bottomRightCorner:
        return gma.AdChoicesPlacement.bottomRightCorner;
    }
  }

  Future<void> _completeLoaded(
    Completer<core.AdLoadResult> completer,
    gma.Ad ad,
    core.AdType adType, {
    _AdmobEventEmitter? events,
  }) async {
    if (completer.isCompleted) {
      ad.dispose();
      events?.close();
      return;
    }
    final emitter = events ?? _AdmobEventEmitter();
    if (ad is gma.AdWithoutView) ad.onPaidEvent = emitter.paid;
    final estimatedRevenueMicros = await _queryEstimatedRevenue(ad, adType);
    if (completer.isCompleted) {
      await ad.dispose();
      emitter.close();
      return;
    }
    completer.complete(
      core.AdLoadResult.success(
        _AdmobLoadedAd(ad, adType, emitter),
        estimatedRevenueMicros: estimatedRevenueMicros,
      ),
    );
  }

  Future<double> _queryEstimatedRevenue(gma.Ad ad, core.AdType adType) async {
    final adId = gma_internal.instanceManager.adIdFor(ad);
    if (adId == null) return 0;
    try {
      final revenue = switch (adType) {
        core.AdType.appOpen => QueryAdRevenue.instance.getOpenAdRevenue(
          adId.toString(),
        ),
        core.AdType.interstitial => QueryAdRevenue.instance.getIntAdRevenue(
          adId.toString(),
        ),
        core.AdType.native => QueryAdRevenue.instance.getNativeAdRevenue(
          adId.toString(),
        ),
        core.AdType.rewarded || core.AdType.banner => Future<double>.value(0),
      };
      final value = await revenue;
      return value.isFinite && value > 0 ? value : 0;
    } catch (_) {
      return 0;
    }
  }

  void _completeFailure(
    Completer<core.AdLoadResult> completer,
    gma.LoadAdError error, {
    String? network,
  }) {
    if (completer.isCompleted) return;
    final resolved = network ?? _networkFromResponse(error.responseInfo);
    completer.complete(
      core.AdLoadResult.failure(
        'code=${error.code} message=${error.message} domain=${error.domain}',
        adNetwork: resolved,
        adSourceName: resolved,
      ),
    );
  }

  void _completeException(
    Completer<core.AdLoadResult> completer,
    Object error,
  ) {
    if (!completer.isCompleted) {
      completer.complete(
        core.AdLoadResult.failure(
          'exception=$error',
          adNetwork: 'Admob',
          adSourceName: 'Admob',
        ),
      );
    }
  }

  @override
  Future<core.UmpConsentResult> handleUmpConsent({
    required String countryCode,
    required bool requiresCmpByLocale,
    Object? params,
    bool loadAndShowFormIfRequired = true,
    bool fetchStatusSnapshot = false,
  }) async {
    if (!requiresCmpByLocale) {
      final canRequest = fetchStatusSnapshot
          ? await gma.ConsentInformation.instance.canRequestAds()
          : true;
      final status = fetchStatusSnapshot
          ? await gma.ConsentInformation.instance.getConsentStatus()
          : gma.ConsentStatus.notRequired;
      final privacy = fetchStatusSnapshot
          ? await gma.ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus()
          : gma.PrivacyOptionsRequirementStatus.notRequired;
      return core.UmpConsentResult(
        countryCode: countryCode,
        requiresCmpByLocale: false,
        canRequestAds: canRequest,
        consentStatus: _consentStatus(status),
        privacyOptionsRequirementStatus: _privacyStatus(privacy),
      );
    }
    final requestParams =
        params as gma.ConsentRequestParameters? ??
        gma.ConsentRequestParameters();
    final requestError = await _requestConsentInfoUpdate(requestParams);
    gma.FormError? formError;
    if (requestError == null && loadAndShowFormIfRequired) {
      formError = await _loadAndShowConsentFormIfRequired();
    }
    final canRequest = await gma.ConsentInformation.instance.canRequestAds();
    final status = await gma.ConsentInformation.instance.getConsentStatus();
    final privacy = await gma.ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    final error = formError ?? requestError;
    return core.UmpConsentResult(
      countryCode: countryCode,
      requiresCmpByLocale: requiresCmpByLocale,
      canRequestAds: canRequest,
      consentStatus: _consentStatus(status),
      privacyOptionsRequirementStatus: _privacyStatus(privacy),
      formError: error == null
          ? null
          : core.FormError(error.errorCode, error.message),
    );
  }

  @override
  Future<bool> canRequestAds() =>
      gma.ConsentInformation.instance.canRequestAds();

  @override
  Future<core.PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    final value = await gma.ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return _privacyStatus(value);
  }

  Future<gma.FormError?> _requestConsentInfoUpdate(
    gma.ConsentRequestParameters params,
  ) {
    final completer = Completer<gma.FormError?>();
    gma.ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => completer.complete(null),
      completer.complete,
    );
    return completer.future;
  }

  Future<gma.FormError?> _loadAndShowConsentFormIfRequired() async {
    final completer = Completer<gma.FormError?>();
    await gma.ConsentForm.loadAndShowConsentFormIfRequired(completer.complete);
    return completer.future;
  }

  @override
  Future<core.FormError?> showPrivacyOptionsForm() async {
    final completer = Completer<gma.FormError?>();
    await gma.ConsentForm.showPrivacyOptionsForm(completer.complete);
    final error = await completer.future;
    return error == null
        ? null
        : core.FormError(error.errorCode, error.message);
  }

  @override
  Future<String?> openAdInspector() {
    final completer = Completer<String?>();
    gma.MobileAds.instance.openAdInspector((error) {
      completer.complete(
        error == null
            ? null
            : 'code=${error.code} domain=${error.domain} '
                  'message=${error.message}',
      );
    });
    return completer.future;
  }

  @override
  Future<bool> closeFullScreenAd() =>
      FlutterBoomPdfAdAdmobPluginsPlatform.instance.closeFullScreenAd();

  @override
  Future<void> updateCloseableFullScreenAdActivityNames(
    Iterable<String> activityNames,
  ) => FlutterBoomPdfAdAdmobPluginsPlatform.instance
      .updateCloseableFullScreenAdActivityNames(activityNames);
}

class _AdmobLoadedAd implements core.LoadedNetworkAd {
  _AdmobLoadedAd(this._ad, this.adType, this._events);

  final gma.Ad _ad;
  final _AdmobEventEmitter _events;
  @override
  final core.AdType adType;
  bool _disposed = false;

  @override
  String get networkId => 'admob';
  @override
  String get adNetwork => _networkFor(_ad);
  @override
  String get adSourceName => _networkFor(_ad);
  @override
  Object get rawAd => _ad;
  @override
  bool get supportsWidget => _ad is gma.AdWithView;
  @override
  Stream<core.AdNetworkEvent> get events => _events.stream;

  @override
  Widget? buildWidget() {
    final ad = _ad;
    return ad is gma.AdWithView ? gma.AdWidget(ad: ad) : null;
  }

  @override
  Future<core.AdShowResult> show({
    core.OnUserEarnedRewardCallback? onUserEarnedReward,
  }) {
    if (_ad is gma.AppOpenAd) return _showAppOpen(_ad);
    if (_ad is gma.InterstitialAd) return _showInterstitial(_ad);
    if (_ad is gma.RewardedAd) {
      return _showRewarded(_ad, onUserEarnedReward);
    }
    return Future.value(
      core.AdShowResult.failure('unsupported-ad-class=${_ad.runtimeType}'),
    );
  }

  Future<core.AdShowResult> _showAppOpen(gma.AppOpenAd ad) async {
    final completer = Completer<core.AdShowResult>();
    ad.fullScreenContentCallback = gma.FullScreenContentCallback<gma.AppOpenAd>(
      onAdShowedFullScreenContent: (_) => _events.impression(),
      onAdDismissedFullScreenContent: (_) {
        _events.closed();
        completer.complete(const core.AdShowResult.success());
      },
      onAdFailedToShowFullScreenContent: (_, error) =>
          completer.complete(core.AdShowResult.failure(_showError(error))),
      onAdClicked: (_) => _events.clicked(),
    );
    try {
      await ad.show();
    } catch (error) {
      return core.AdShowResult.failure('exception=$error');
    }
    return completer.future;
  }

  Future<core.AdShowResult> _showInterstitial(gma.InterstitialAd ad) async {
    final completer = Completer<core.AdShowResult>();
    ad.fullScreenContentCallback =
        gma.FullScreenContentCallback<gma.InterstitialAd>(
          onAdShowedFullScreenContent: (_) => _events.impression(),
          onAdDismissedFullScreenContent: (_) {
            _events.closed();
            completer.complete(const core.AdShowResult.success());
          },
          onAdFailedToShowFullScreenContent: (_, error) =>
              completer.complete(core.AdShowResult.failure(_showError(error))),
          onAdClicked: (_) => _events.clicked(),
        );
    try {
      await ad.show();
    } catch (error) {
      return core.AdShowResult.failure('exception=$error');
    }
    return completer.future;
  }

  Future<core.AdShowResult> _showRewarded(
    gma.RewardedAd ad,
    core.OnUserEarnedRewardCallback? callback,
  ) async {
    final completer = Completer<core.AdShowResult>();
    ad.fullScreenContentCallback =
        gma.FullScreenContentCallback<gma.RewardedAd>(
          onAdShowedFullScreenContent: (_) => _events.impression(),
          onAdDismissedFullScreenContent: (_) {
            _events.closed();
            completer.complete(const core.AdShowResult.success());
          },
          onAdFailedToShowFullScreenContent: (_, error) =>
              completer.complete(core.AdShowResult.failure(_showError(error))),
          onAdClicked: (_) => _events.clicked(),
        );
    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) => callback?.call(
          ad,
          core.AdRewardItem(amount: reward.amount, type: reward.type),
        ),
      );
    } catch (error) {
      return core.AdShowResult.failure('exception=$error');
    }
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ad.dispose();
    await _events.close();
  }
}

class _AdmobEventEmitter {
  final StreamController<core.AdNetworkEvent> _controller =
      StreamController<core.AdNetworkEvent>.broadcast(sync: true);
  bool _closed = false;

  Stream<core.AdNetworkEvent> get stream => _controller.stream;

  void impression() => _add(const core.AdNetworkEvent.impression());
  void clicked() => _add(const core.AdNetworkEvent.clicked());
  void closed() => _add(const core.AdNetworkEvent.closed());

  void paid(
    gma.Ad _,
    double valueMicros,
    gma.PrecisionType precision,
    String currencyCode,
  ) {
    _add(
      core.AdNetworkEvent.paid(
        valueMicros: valueMicros,
        currencyCode: currencyCode,
        precisionType: precision.name,
      ),
    );
  }

  void _add(core.AdNetworkEvent event) {
    if (!_closed) _controller.add(event);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _controller.close();
  }
}

String _networkFor(gma.Ad ad) => _networkFromResponse(ad.responseInfo);

String _networkFromResponse(gma.ResponseInfo? responseInfo) {
  final value = responseInfo?.loadedAdapterResponseInfo?.adSourceName.trim();
  return value == null || value.isEmpty ? 'Admob' : value;
}

String _showError(gma.AdError error) =>
    'code=${error.code} message=${error.message} domain=${error.domain}';

core.ConsentStatus _consentStatus(gma.ConsentStatus value) {
  return core.ConsentStatus.values.firstWhere(
    (item) => item.name == value.name,
    orElse: () => core.ConsentStatus.unknown,
  );
}

core.PrivacyOptionsRequirementStatus _privacyStatus(
  gma.PrivacyOptionsRequirementStatus value,
) {
  return core.PrivacyOptionsRequirementStatus.values.firstWhere(
    (item) => item.name == value.name,
    orElse: () => core.PrivacyOptionsRequirementStatus.unknown,
  );
}
