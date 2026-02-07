//
//  AppDelegate.swift
//  BounceBallGame
//
//  Created by Abhinav Unnam on 08/10/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Start initial session immediately (background queue handles network)
        AnalyticsService.shared.startSession()
        
        // Delay Game Center auth slightly to prevent launch-time hangs/crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            GameCenterHelper.shared.authenticate { success in
                let playerId = GameCenterHelper.shared.getCurrentPlayerId()
                print("AppDelegate: Game Center auth finished. Success: \(success). ID: \(playerId)")
                
                // Update the existing session with the real Player ID
                AnalyticsService.shared.updatePlayerId(playerId)
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // End analytics session when app goes to background
        AnalyticsService.shared.endSession()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Start new analytics session when returning to foreground
        AnalyticsService.shared.startSession()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // End analytics session when app is terminated
        AnalyticsService.shared.endSession()
    }


}

