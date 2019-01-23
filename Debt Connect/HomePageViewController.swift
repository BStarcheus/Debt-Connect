//
//  HomePageViewController.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 8/17/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import UIKit
import os.log


class HomePageViewController: UIViewController, ConnectedUserAPI {

	
	var sheetsAPI: SheetsAPI?
	
	func getAPI() -> SheetsAPI? {
		return self.sheetsAPI
	}
	
	func setAPI(_ api: SheetsAPI?) {
		if (api != nil) {
			self.sheetsAPI = api
		}
	}
	
	//MARK: Properties
	@IBOutlet weak var oweName: UILabel!
	@IBOutlet weak var price: UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("will")
		print(self)
		print(self.tabBarController!.selectedViewController!)
		let vc = self.tabBarController?.selectedViewController as! ConnectedUserAPI
		self.setAPI(vc.getAPI())
		print(sheetsAPI?.connectedUser.name as Any)
		
		self.sheetsAPI?.updateSum()
		self.refresh()
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print("Hello there")
		print(GIDSignIn.sharedInstance().currentUser)
		
		//If there is no stored user, display the launch log in screen
		if (GIDSignIn.sharedInstance()?.hasAuthInKeychain() == false) {
			let vc = self.storyboard?.instantiateViewController(withIdentifier: "launch") as! LaunchViewController
			present(vc, animated: true, completion: nil)
		} else {
			if let tempList = sheetsAPI?.loadConnectedUsers(), tempList.count > 0 {
			} else {
				
				if sheetsAPI?.connectedUser.name == "" && sheetsAPI?.connectedUser.sheetInDrive == "" {
					sheetsAPI?.choosePath()
					print("tried to choose")
				}
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	func refresh() {
		var first: String?
		var second: String?
		var someSum: Float?
		var sumString: String?
		
		if let _ = self.sheetsAPI, self.sheetsAPI?.connectedUser.sum != "" {
			someSum = Float(self.sheetsAPI!.connectedUser.sum)!
			
			//If the sum in the cell is >0, and the other person is first, then this user owes them.
			//If the sum is >0 and this user is first, the other person owes them.
			if ((someSum! < 0 && (self.sheetsAPI?.connectedUser.isFirst)!) || (someSum! > 0 && !(self.sheetsAPI?.connectedUser.isFirst)!)) {
				first = self.sheetsAPI?.connectedUser.name
				second = " owes you"
			} else if ((someSum! > 0 && (self.sheetsAPI?.connectedUser.isFirst)!) || (someSum! < 0 && !(self.sheetsAPI?.connectedUser.isFirst)!)) {
				first = "You owe "
				second = self.sheetsAPI?.connectedUser.name
			}
			sumString = String(abs(someSum!))
		}
		
		
		self.price.text = "$" + (sumString ?? "")
		self.oweName.text = (first ?? "You owe") + (second ?? "")
		
	}
	
	
}
