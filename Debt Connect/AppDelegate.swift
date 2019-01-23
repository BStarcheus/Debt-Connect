//
//  AppDelegate.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 8/17/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import UIKit
import os.log


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
	

	var window: UIWindow?
	
	
	// MARK: GoogleSignIn

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		//Initialize sign in
		GIDSignIn.sharedInstance().clientID = "590767009386-p3i8usnkimtraoahv5ck2j1qs035a0on.apps.googleusercontent.com"
		GIDSignIn.sharedInstance().delegate = self
		

		//Add the Drive Scope to the scopes to request
		let newSheetsScope = "https://www.googleapis.com/auth/drive"
		GIDSignIn.sharedInstance()?.scopes.append(newSheetsScope)
		
		
		GIDSignIn.sharedInstance().signInSilently()
		
		print(GIDSignIn.sharedInstance().currentUser)
		return true
	}
	
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
		if let error = error {
			print("\(error.localizedDescription)")
			os_log("Error signing in", log: .default, type: .debug)
		} else {
			let newUser: GIDGoogleUser = GIDSignIn.sharedInstance().currentUser
			
			print(newUser)
			print(newUser.userID)
			print(newUser.grantedScopes)
			print(GIDSignIn.sharedInstance().scopes)
			
			let connected = SheetsAPI()
			
			//Find the previously used user in storage
			if let userStorage = connected.loadConnectedUsers() {
				if userStorage.count > 0 {
					let lastUsed = userStorage[0]
					connected.connectedUser = lastUsed
					print(lastUsed)
					print(connected.connectedUser)
				}
			}
			
			
			//If in the launch view, it has finished logging in so dismiss the window
			if let launchView = window?.rootViewController?.presentedViewController as? LaunchViewController {
				launchView.dismiss(animated: true, completion: nil)
			}
			
			//If in settings, it will need to refresh the screen
			//This is only a backup, in case the viewDidAppear method runs before google can log in, which is rare
			if let tabBar = window?.rootViewController as? UITabBarController {
				
				let currentView = tabBar.selectedViewController as? ConnectedUserAPI
				currentView?.setAPI(connected)
				
				
				if let _ = tabBar.presentedViewController as? LaunchViewController {
				} else {
					
					if currentView?.getAPI()?.connectedUser.name == "" {
						currentView?.getAPI()?.choosePath()
					}
				}
				
				
				
				if let homeView = tabBar.selectedViewController as? HomePageViewController {
					homeView.refresh()
				}
				
				if let setView = tabBar.selectedViewController as? SettingsViewController {
					setView.refreshPage()
				}
			}
		}
	}
	
	func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
		
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		return GIDSignIn.sharedInstance().handle(url as URL?,
												 sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
												 annotation: UIApplication.OpenURLOptionsKey.annotation)
	}
	
	
	
	
	
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

