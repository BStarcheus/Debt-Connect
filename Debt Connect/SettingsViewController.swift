//
//  SettingsViewController.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 8/17/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import UIKit


class SettingsViewController: UIViewController, GIDSignInUIDelegate, ConnectedUserAPI {
	
	//MARK: Properties
	
	var sheetsAPI: SheetsAPI?
	
	func getAPI() -> SheetsAPI? {
		return self.sheetsAPI
	}
	
	func setAPI(_ api: SheetsAPI?) {
		if (api != nil) {
			self.sheetsAPI = api
		}
	}
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var emailLabel: UILabel!
	
	@IBOutlet weak var signInButton: GIDSignInButton!
	@IBOutlet weak var signOutButton: UIButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		GIDSignIn.sharedInstance()?.uiDelegate = self
        // Do any additional setup after loading the view.
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	
		
		print("will")
		print(self)
		print(self.tabBarController!.selectedViewController!)
		let vc = self.tabBarController?.selectedViewController as! ConnectedUserAPI
		self.setAPI(vc.getAPI())
		print(sheetsAPI?.connectedUser.name as Any)
		
		refreshPage()
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let tempList = sheetsAPI?.loadConnectedUsers(), tempList.count > 0 {
		} else {
			
			if sheetsAPI?.connectedUser.name == "" && sheetsAPI?.connectedUser.sheetInDrive == "" {
				sheetsAPI?.choosePath()
			}
		}
		
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func refreshPage() {
		//If there is a user, display the log out buttons
		if (GIDSignIn.sharedInstance()?.currentUser != nil) {
			signInButton.isHidden = true
			signOutButton.isHidden = false
		} else {
			signInButton.isHidden = false
			signOutButton.isHidden = true
		}
		GIDSignIn.sharedInstance()?.uiDelegate = self
		
		nameLabel.text = sheetsAPI?.connectedUser.name
		emailLabel.text = sheetsAPI?.connectedUser.email
		
	}
	
	
	@IBAction func signOutButton(_ sender: UIButton) {
		GIDSignIn.sharedInstance().signOut()
		sheetsAPI?.connectedUser = ConnectedUser("", "", false, "", "", false)
		sheetsAPI?.saveConnectedUsers([ConnectedUser]())
		refreshPage()
	}
	
	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		
		let vc = self as ConnectedUserAPI
		let nav = segue.destination as! UINavigationController
		let newVC = nav.viewControllers[0] as! ConnectedUsersTableViewController
		newVC.setAPI(vc.getAPI())
		print(sheetsAPI?.connectedUser.name as Any)
    }
	
	@IBAction func unwindFromList(sender: UIStoryboardSegue) {
		if let sourceVC = sender.source as? ConnectedUsersTableViewController {
			self.setAPI(sourceVC.getAPI())
		}
		print(sheetsAPI?.connectedUser.name as Any)
	}
	
	

}
