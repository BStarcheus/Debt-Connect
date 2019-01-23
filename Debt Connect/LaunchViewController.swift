//
//  LaunchViewController.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 12/19/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import UIKit
import os.log


class LaunchViewController: UIViewController, GIDSignInUIDelegate, ConnectedUserAPI {
	
	
	var sheetsAPI: SheetsAPI?
	
	func getAPI() -> SheetsAPI? {
		return self.sheetsAPI
	}
	
	func setAPI(_ api: SheetsAPI?) {
		if (api != nil) {
			self.sheetsAPI = api
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		GIDSignIn.sharedInstance().uiDelegate = self
		
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		
		print("will")
		print(self)
		print(UIApplication.shared.keyWindow?.rootViewController as Any)
		
		if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
			if let vc = tabBar.selectedViewController as? ConnectedUserAPI {
				self.setAPI(vc.getAPI())
				print(sheetsAPI?.connectedUser.name as Any)
			}
		}
		
		print(GIDSignIn.sharedInstance().currentUser)
		
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print(GIDSignIn.sharedInstance().currentUser)
		print("Did appear")
	}
	
    // MARK: - Navigation
/*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
		
    }
*/

}
