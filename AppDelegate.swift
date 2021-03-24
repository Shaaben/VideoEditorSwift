//
//  AppDelegate.swift
//  Test
//
//  Created by Smart Mobile Tech on 1/29/21.
//

import UIKit
import Adjust
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate
{
    var window: UIWindow?
    var schemeURL = ""
    var addressURL = ""
    let gcmMessageIDKey = "gcm.Message_ID"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        let yourAppToken = "ej5vgpt7ob28"
        let environment = ADJEnvironmentProduction
        let adjustConfig = ADJConfig(appToken: yourAppToken, environment: environment)
        adjustConfig?.sendInBackground = true
        adjustConfig?.delegate = self
        Adjust.appDidLaunch(adjustConfig)
        
        let deeplinkURL = "iosapptest://applink?M=t&serviceId=1501"
        UserDefaults.standard.setValue(deeplinkURL, forKey: "deeplinkURL")
        UserDefaults.standard.synchronize()

        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
         Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?)
    {
        let userDefault = UserDefaults.standard
        userDefault.set(fcmToken, forKey: "TOKEN")
        userDefault.synchronize()
        
        Adjust.setPushToken(fcmToken!)
        print("FCM "+fcmToken!)

        let adjustEvent = ADJEvent(eventToken: "79ieul")
        adjustEvent?.addCallbackParameter("eventValue", value: fcmToken ?? "")
        let deeplink = UserDefaults.standard.object(forKey: "deeplinkURL") as? String
        adjustEvent?.addCallbackParameter("deeplink", value: deeplink ?? "")
        Adjust.trackEvent(adjustEvent)
    }
    
    private func application(application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Messaging.messaging().apnsToken = deviceToken as Data
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}

extension AppDelegate: AdjustDelegate
{
    func adjustAttributionChanged(_ attribution: ADJAttribution?)
    {
        print(attribution?.adid ?? "")
    }
    
    func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?)
    {
      print(eventSuccessResponseData?.jsonResponse ?? [:])
    }

    func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?)
    {
      print(eventFailureResponseData?.jsonResponse ?? [:])
    }

    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?)
    {
      print(sessionFailureResponseData?.jsonResponse ?? [:])
    }
    
    // MARK: - HANDLE Deeplink response
    private func handleDeeplink(deeplink url: URL?)
    {
        print("Handling Deeplink")
        print(url?.absoluteString ?? "Not found")
        UserDefaults.standard.setValue(url?.absoluteString, forKey: "deeplinkURL")
        UserDefaults.standard.synchronize()
        startApp()
    }
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool
    {
        handleDeeplink(deeplink: deeplink)
        return true
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool
    {
        // Pass deep link to Adjust in order to potentially reattribute user.
        print("Universal link opened an app:")
        print(url.absoluteString)
        Adjust.appWillOpen(url)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            print("Universal link opened an app: %@", userActivity.webpageURL!.absoluteString)
            if let webURL = userActivity.webpageURL {
                let oldStyleDeeplink = Adjust.convertUniversalLink(webURL, scheme: "e9ua.adj.st")
                handleDeeplink(deeplink: oldStyleDeeplink)
                Adjust.appWillOpen(userActivity.webpageURL!)
            }
        }
        return true
    }
    
    func startApp()
    {
        if let deeplinkURL = UserDefaults.standard.value(forKey: "deeplinkURL") as? String
        {
            if schemeURL.isEmpty
            {
                if UserDefaults.standard.value(forKey: "customURL") == nil
                {
                    self.createCustomURL(url: "https://liteoffersapps-eu.s3.eu-central-1.amazonaws.com/index.html", deeplinkURL: deeplinkURL)
                }
                let webView = initWebViewURL()
                self.present(webView: webView)
            }
            else if schemeURL.hasPrefix("iossdk://")
            {
                let urlToOpen = URL(string: self.addressURL.removingPercentEncoding!)
                if (urlToOpen != nil)
                {
                    let storyBoard = UIStoryboard(name: "Main", bundle:nil)
                    let webView = storyBoard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
                    webView.urlToOpen = urlToOpen!
                    self.present(webView: webView)
                }
            }
            else
            {
                let url = URL(string: schemeURL)
                self.schemeURL = "iossdk://"
                self.startApp()
                if UIApplication.shared.canOpenURL(url!)
                {
                    UIApplication.shared.open(url!)
                }
            }
        }
        else
        {
            self.present()
        }
    }
    
    func createCustomURL(url: String, deeplinkURL: String)
    {
        let lang = Locale.current.languageCode ?? ""
        let packageName = Bundle.main.bundleIdentifier ?? ""
        let uuid = UIDevice.current.identifierForVendor!.uuidString
        let idfa = Adjust.adid() ?? ""
        let adid = Adjust.idfa() ?? ""
        var fScheme = "iossdk://"
        fScheme = fScheme.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        var d = deeplinkURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        d = d.replacingOccurrences(of: "=", with: "%3D", options: .literal, range: nil)
        d = d.replacingOccurrences(of: "&", with: "%26", options: .literal, range: nil)
        let string =  "\(url)?packageName=\(packageName)&flowName=iosBA&lang=\(lang)&deviceId=\(uuid)&AdjustId=\(idfa)&gpsAdid=\(adid)&referringLink=\(d)&fScheme=\(fScheme)"
        UserDefaults.standard.setValue(string, forKey: "customURL")
        UserDefaults.standard.synchronize()
    }
    
    func initWebViewURL() -> WebViewController
    {
        let customURL = UserDefaults.standard.value(forKey: "customURL") as! String
        let urlToOpen = URL(string: customURL)
        let storyBoard = UIStoryboard(name: "Main", bundle:nil)
        let webView = storyBoard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        webView.urlToOpen = urlToOpen!
        
        return webView
    }
    
    func present(webView: WebViewController)
    {
        UIApplication.shared.windows.first?.rootViewController = webView
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func present()
    {
        let url = URL(string: schemeURL)
        let storyBoard = UIStoryboard(name: "Main", bundle:nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        view.queryDictionary = (url?.queryDictionary)!
        let nav = UINavigationController(rootViewController: view)
        UIApplication.shared.windows.first?.rootViewController = nav
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}

private extension URL
{
    var queryDictionary: [String: Any]? {
        var queryStrings = [String: String]()
        guard let query = self.query else { return queryStrings }
        for pair in query.components(separatedBy: "&")
        {
            if (pair.components(separatedBy: "=").count > 1)
            {
                let key = pair.components(separatedBy: "=")[0]
                let value = pair
                    .components(separatedBy: "=")[1]
                    .replacingOccurrences(of: "+", with: " ")
                    .removingPercentEncoding ?? ""
                
                queryStrings[key] = value
            }
        }
        return queryStrings
    }
}

