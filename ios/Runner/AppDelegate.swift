import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      if apiKey == "YOUR_IOS_GOOGLE_MAPS_API_KEY" {
        NSLog("Google Maps API key placeholder detected. Replace GMSApiKey in Info.plist with a valid key before releasing.")
      }
    } else {
      NSLog("Google Maps API key is missing. Add GMSApiKey to Info.plist to enable map features.")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
