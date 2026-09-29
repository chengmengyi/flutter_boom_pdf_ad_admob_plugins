package com.boom.pdf.ad.admob.flutter_boom_pdf_ad_admob_plugins

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import java.util.Collections
import java.util.WeakHashMap

class FlutterBoomPdfAdAdmobPluginsPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var nativeAdHeadlineEventChannel: EventChannel
    private var nativeAdHeadlineEventSink: EventChannel.EventSink? = null
    private val pendingNativeAdHeadlineEvents = ArrayDeque<Map<String, Any?>>()
    private var binding: FlutterPluginBinding? = null
    private var application: Application? = null
    private var compactFactory: GuideCompactNativeAdFactory? = null
    private var compactRegistered = false
    private var fullScreenRegistered = false
    private var layoutName: String? = null
    private val activities = Collections.newSetFromMap(WeakHashMap<Activity, Boolean>())
    private val closeableNames = linkedSetOf(
        "com.google.android.gms.ads.AdActivity",
        "com.facebook.ads.AudienceNetworkActivity",
        "com.facebook.ads.InterstitialAdActivity",
        "com.applovin.adview.AppLovinFullscreenActivity",
        "com.bytedance.sdk.openadsdk.activity.TTFullScreenVideoActivity",
        "com.bytedance.sdk.openadsdk.activity.TTInterstitialActivity",
        "com.bytedance.sdk.openadsdk.activity.TTRewardVideoActivity",
        "com.vungle.warren.ui.VungleActivity",
        "com.vungle.ads.internal.ui.VungleActivity",
        "com.unity3d.services.ads.adunit.AdUnitActivity",
        "com.ironsource.sdk.controller.ControllerActivity",
        "com.mbridge.msdk.reward.player.MBRewardVideoActivity"
    )
    private val lifecycle = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, state: Bundle?) = track(activity)
        override fun onActivityStarted(activity: Activity) = track(activity)
        override fun onActivityResumed(activity: Activity) = track(activity)
        override fun onActivityPaused(activity: Activity) = Unit
        override fun onActivityStopped(activity: Activity) = Unit
        override fun onActivitySaveInstanceState(activity: Activity, state: Bundle) = Unit
        override fun onActivityDestroyed(activity: Activity) {
            activities.remove(activity)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        binding = flutterPluginBinding
        application = flutterPluginBinding.applicationContext as? Application
        application?.registerActivityLifecycleCallbacks(lifecycle)
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "flutter_boom_pdf_ad_admob_plugins"
        )
        channel.setMethodCallHandler(this)
        nativeAdHeadlineEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "flutter_boom_pdf_ad_admob_plugins/native_ad_headline"
        )
        nativeAdHeadlineEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "configureSmallNativeAdLayout" -> {
                layoutName = call.argument<String>("layoutName")?.trim()?.takeIf { it.isNotEmpty() }
                ensureFactories()
                compactFactory?.layoutName = layoutName
                result.success(null)
            }
            "closeFullScreenAd" -> result.success(closeFullScreenAd())
            "updateCloseableFullScreenAdActivityNames" -> {
                call.argument<List<String>>("activityNames").orEmpty()
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }
                    .forEach(closeableNames::add)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun ensureFactories() {
        val current = binding ?: return
        if (!compactRegistered) {
            val factory = GuideCompactNativeAdFactory(
                current.applicationContext,
                ::emitNativeAdHeadline
            )
            factory.layoutName = layoutName
            compactRegistered = GoogleMobileAdsPlugin.registerNativeAdFactory(
                current.flutterEngine,
                "guide_compact_native",
                factory
            )
            if (compactRegistered) compactFactory = factory
        }
        if (!fullScreenRegistered) {
            fullScreenRegistered = GoogleMobileAdsPlugin.registerNativeAdFactory(
                current.flutterEngine,
                "full_screen_native",
                FullScreenNativeAdFactory(
                    current.applicationContext,
                    ::emitNativeAdHeadline
                )
            )
        }
    }

    private fun track(activity: Activity) {
        if (isCloseable(activity)) activities.add(activity)
    }

    private fun isCloseable(activity: Activity): Boolean {
        val type = activity.javaClass
        return closeableNames.any { name ->
            name == type.name || runCatching { Class.forName(name).isAssignableFrom(type) }.getOrDefault(false)
        }
    }

    private fun closeFullScreenAd(): Boolean {
        var closed = false
        activities.toList().filter(::isCloseable).forEach { activity ->
            if (!activity.isFinishing && !activity.isDestroyed) {
                activity.finish()
                closed = true
            }
        }
        return closed
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        nativeAdHeadlineEventSink = events
        if (events == null) return
        while (pendingNativeAdHeadlineEvents.isNotEmpty()) {
            events.success(pendingNativeAdHeadlineEvents.removeFirst())
        }
    }

    override fun onCancel(arguments: Any?) {
        nativeAdHeadlineEventSink = null
    }

    private fun emitNativeAdHeadline(
        headline: String?,
        token: String?,
        isNextGenAdmob: Boolean
    ) {
        if (token.isNullOrBlank()) return
        val event = mapOf<String, Any?>(
            "headline" to headline,
            "token" to token,
            "isNextGenAdmob" to isNextGenAdmob
        )
        Handler(Looper.getMainLooper()).post {
            val sink = nativeAdHeadlineEventSink
            if (sink != null) {
                sink.success(event)
                return@post
            }
            if (pendingNativeAdHeadlineEvents.size >= MAX_PENDING_NATIVE_AD_HEADLINES) {
                pendingNativeAdHeadlineEvents.removeFirst()
            }
            pendingNativeAdHeadlineEvents.addLast(event)
        }
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPluginBinding) {
        if (compactRegistered) {
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(
                flutterPluginBinding.flutterEngine,
                "guide_compact_native"
            )
        }
        if (fullScreenRegistered) {
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(
                flutterPluginBinding.flutterEngine,
                "full_screen_native"
            )
        }
        application?.unregisterActivityLifecycleCallbacks(lifecycle)
        activities.clear()
        channel.setMethodCallHandler(null)
        nativeAdHeadlineEventChannel.setStreamHandler(null)
        nativeAdHeadlineEventSink = null
        pendingNativeAdHeadlineEvents.clear()
        compactFactory = null
        application = null
        binding = null
    }

    private companion object {
        const val MAX_PENDING_NATIVE_AD_HEADLINES = 32
    }
}
