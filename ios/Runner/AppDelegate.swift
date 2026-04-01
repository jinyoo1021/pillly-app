import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    _registerNotificationCategories()
    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  private func _registerNotificationCategories() {
    // Taken action
    let doneAction = UNNotificationAction(
      identifier: "ACTION_DONE",
      title: "Taken ✓",
      options: [.authenticationRequired]
    )

    // Skip action
    let skipAction = UNNotificationAction(
      identifier: "ACTION_SKIP",
      title: "Skip ✗",
      options: []
    )

    // PILL_REMINDER category
    let pillCategory = UNNotificationCategory(
      identifier: "PILL_REMINDER",
      actions: [doneAction, skipAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current()
      .setNotificationCategories([pillCategory])
  }
}