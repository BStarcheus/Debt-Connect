//
//  AddPurchaseViewController.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 8/17/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import UIKit
import os.log


class AddPurchaseViewController: UIViewController, UITextFieldDelegate, ConnectedUserAPI {

	//MARK: Properties
	
	var sheetsAPI: SheetsAPI?
	
	@IBOutlet weak var item: UITextField!
	@IBOutlet weak var price: UITextField!
	@IBOutlet weak var date: UITextField!
	@IBOutlet weak var notes: UITextField!
	@IBOutlet weak var addButton: UIButton!
	
	
	func getAPI() -> SheetsAPI? {
		return self.sheetsAPI
	}
	
	func setAPI(_ api: SheetsAPI?) {
		if (api != nil) {
			self.sheetsAPI = api
		}
	}
	
	
	@IBAction func addButton(_ sender: UIButton) {
		self.sheetsAPI?.addNewEntry(item.text!, price.text!, date.text!, notes.text ?? "")
		addButton.isEnabled = false
	}
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		item.delegate = self
		price.delegate = self
		date.delegate = self
		notes.delegate = self
		
		addButton.titleLabel?.adjustsFontSizeToFitWidth = true
		
		updateAddButtonState()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("will")
		print(self)
		print(self.tabBarController!.selectedViewController!)
		let vc = self.tabBarController?.selectedViewController as! ConnectedUserAPI
		self.setAPI(vc.getAPI())
		print(sheetsAPI?.connectedUser.name as Any)
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		//If there is no stored user, display the launch log in screen
		if (GIDSignIn.sharedInstance()?.hasAuthInKeychain() == false) {
			let vc = self.storyboard?.instantiateViewController(withIdentifier: "launch") as! LaunchViewController
			present(vc, animated: true, completion: nil)
		} else {
			if let tempList = sheetsAPI?.loadConnectedUsers(), tempList.count > 0 {
			} else {
				
				if sheetsAPI?.connectedUser.name == "" && sheetsAPI?.connectedUser.sheetInDrive == "" {
					sheetsAPI?.choosePath()
				}
			}
		}
		
		
	}
	

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	//MARK: UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		addButton.isEnabled = false
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		updateAddButtonState()
	}
	
	
	
	//MARK: Private Methods
	
	private func updateAddButtonState() {
		if let _ = item.text, let _ = price.text, let _ = date.text {
			addButton.isEnabled = true
		} else {
			addButton.isEnabled = false
		}
	}
	
}
