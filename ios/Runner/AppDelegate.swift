import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerScreenChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// Keeps the display on for the length of a prompter session.
  private func registerScreenChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "teleprompter/screen",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "enableKeepAwake":
        UIApplication.shared.isIdleTimerDisabled = true
        result(nil)
      case "disableKeepAwake":
        UIApplication.shared.isIdleTimerDisabled = false
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
