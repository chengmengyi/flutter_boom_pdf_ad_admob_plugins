package com.boom.pdf.ad.admob.flutter_boom_pdf_ad_admob_plugins

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class FullScreenNativeAdFactory(
    private val context: Context
) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.fpad_full_screen_native_ad, null) as NativeAdView
        val media = adView.findViewById<MediaView>(R.id.fpad_ad_media)
        val headline = adView.findViewById<TextView>(R.id.fpad_ad_headline)
        val body = adView.findViewById<TextView>(R.id.fpad_ad_body)
        val cta = adView.findViewById<Button>(R.id.fpad_ad_call_to_action)
        adView.mediaView = media
        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta
        headline.text = nativeAd.headline.orEmpty()
        body.text = nativeAd.body ?: nativeAd.advertiser ?: nativeAd.store.orEmpty()
        body.visibility = if (body.text.isBlank()) View.GONE else View.VISIBLE
        cta.text = nativeAd.callToAction ?: "Open"
        cta.visibility = View.VISIBLE
        adView.setNativeAd(nativeAd)
        return adView
    }
}
