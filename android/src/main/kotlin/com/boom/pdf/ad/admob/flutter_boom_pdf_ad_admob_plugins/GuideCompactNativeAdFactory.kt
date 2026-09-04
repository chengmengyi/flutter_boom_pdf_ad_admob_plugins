package com.boom.pdf.ad.admob.flutter_boom_pdf_ad_admob_plugins

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class GuideCompactNativeAdFactory(
    private val context: Context
) : GoogleMobileAdsPlugin.NativeAdFactory {
    var layoutName: String? = null

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val name = layoutName?.trim().orEmpty()
        require(name.isNotEmpty()) { "Missing configured layout name for compact native ad" }
        val layoutId = context.resources.getIdentifier(name, "layout", context.packageName)
        require(layoutId != 0) { "Missing layout resource: $name" }
        val adView = LayoutInflater.from(context).inflate(layoutId, null) as NativeAdView
        val icon = adView.findViewById<ImageView?>(id("ad_app_icon"))
        val headline = adView.findViewById<TextView?>(id("ad_headline"))
        val body = adView.findViewById<TextView?>(id("ad_body"))
        val cta = adView.findViewById<TextView?>(id("ad_call_to_action"))
        if (icon != null) {
            adView.iconView = icon
            icon.setImageDrawable(nativeAd.icon?.drawable)
            icon.visibility = if (nativeAd.icon?.drawable == null) View.INVISIBLE else View.VISIBLE
        }
        if (headline != null) {
            adView.headlineView = headline
            headline.text = nativeAd.headline.orEmpty()
        }
        if (body != null) {
            adView.bodyView = body
            body.text = nativeAd.body ?: nativeAd.advertiser ?: nativeAd.store.orEmpty()
            body.visibility = if (body.text.isBlank()) View.INVISIBLE else View.VISIBLE
        }
        if (cta != null) {
            adView.callToActionView = cta
            cta.text = nativeAd.callToAction ?: "Install"
            cta.visibility = View.VISIBLE
        }
        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun id(name: String): Int =
        context.resources.getIdentifier(name, "id", context.packageName)
}
