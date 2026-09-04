import Flutter
import UIKit

public class FlutterBoomPdfAdAdmobPluginsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_boom_pdf_ad_admob_plugins", binaryMessenger: registrar.messenger())
    let instance = FlutterBoomPdfAdAdmobPluginsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "configureSmallNativeAdLayout":
      result(nil)
    case "closeFullScreenAd":
      result(false)
    case "updateCloseableFullScreenAdActivityNames":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
