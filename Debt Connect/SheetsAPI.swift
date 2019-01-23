//
//  UserData.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 12/28/18.
//  Copyright © 2018 Brandon Starcheus. All rights reserved.
//

import os.log


protocol ConnectedUserAPI {
	func getAPI() -> SheetsAPI?
	func setAPI(_ api: SheetsAPI?)
}



class SheetsAPI {
	
	var connectedUser: ConnectedUser
	
	var driveService = GTLRDriveService()
	var sheetsService = GTLRSheetsService()
	
	
	
	
	init() {
		driveService.authorizer = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
		sheetsService.authorizer = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
		connectedUser = ConnectedUser("", "", false, "", "", false)
	}
	
	
	
	
	
	
	//MARK: Local Data
	
	
	func loadConnectedUsers() -> [ConnectedUser]? {
		return NSKeyedUnarchiver.unarchiveObject(withFile: ConnectedUser.ArchiveURL.path) as? [ConnectedUser]
	}
	
	func saveConnectedUsers(_ connectedUsers: [ConnectedUser]) {
		let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(connectedUsers, toFile: ConnectedUser.ArchiveURL.path)
		
		if isSuccessfulSave {
			os_log("ConnectedUsers successfully saved.", log: OSLog.default, type: .debug)
		} else {
			os_log("Failed to save ConnectedUsers.", log: OSLog.default, type: .error)
		}
	}
	
	
	func updateList(_ user: ConnectedUser) {
		var usersList = [ConnectedUser]()
		
		if let list = loadConnectedUsers() {
			usersList = list
		}
		print(usersList)
		
		//Either update or add the user. If user name already exists, update their listing
		//This is because queries have a delay, so this must be updated each time a value of the user is updated
		
		var update = false
		var ind: Int?
		for someUser in usersList {
			if someUser.name == connectedUser.name {
				update = true
				ind = usersList.firstIndex(of: someUser)!
			}
		}
		if update {
			usersList.remove(at: ind!)
		}
		
		usersList.insert(user, at: 0)
		print(usersList)
		saveConnectedUsers(usersList)
	}
	
	
	
	
	
	// MARK: Choices of ChoosePath()
	
	
	//Attempts to find an existing sheet in this user's account
	func findSheet(_ name: String) {
		let query = GTLRDriveQuery_FilesList.query()
		query.q = "name contains 'Debt Connect: ' and name contains '\(GIDSignIn.sharedInstance().currentUser.profile.givenName!)' and name contains '\(name)' and mimeType = 'application/vnd.google-apps.spreadsheet'"
		
		driveService.executeQuery(query, completionHandler: { (ticket, result, NSError) in
			if let error = NSError {
				print(error)
				self.noSheetFound(name)
			} else {
				let response = result as! GTLRDrive_FileList
				
				if (response.files!.count == 0) {
					self.noSheetFound(name)
				} else {
					self.connectedUser = ConnectedUser(name, "", false, "", "", false)
					
					let foundFile = response.files![0]
					self.connectedUser.sheetInDrive = foundFile.identifier!
					self.findSharedEmailInSheet()
					self.findIfShared()
					self.findIfIsFirst()
					self.updateSum()
					
					self.updateList(self.connectedUser)
					print(self.connectedUser.sheetInDrive, "in find sheet")
					
					if let nav = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? UINavigationController {
						if let newVC = nav.viewControllers[0] as? ConnectedUsersTableViewController {
							newVC.dismiss(animated: true, completion: nil)
						}
					}
				}
			}
		})
		
	}
	
	//Creates the spreadsheet on this user's account
	func createSheet(_ name: String, _ email: String) {
		
		let sheet = GTLRSheets_Spreadsheet.init()
		let properties = GTLRSheets_SpreadsheetProperties.init()
		
		properties.title = "Debt Connect: \(GIDSignIn.sharedInstance().currentUser.profile.givenName!) and \(name)"
		sheet.properties = properties
		
		let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: sheet)

		sheetsService.executeQuery(query, completionHandler: { (ticket, result, NSError) in
			if let error = NSError {
				print(error)
			} else {
				let response = result as! GTLRSheets_Spreadsheet
				self.connectedUser.sheetInDrive = response.spreadsheetId!
				self.connectedUser.isFirst = false
				
				self.shareFile(email)
				self.firstTimeSetup()
				
				
				if let nav = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? UINavigationController {
					if let newVC = nav.viewControllers[0] as? ConnectedUsersTableViewController {
						newVC.dismiss(animated: true, completion: nil)
					}
				}
			}
		})
	}
	
	
	
	
	//MARK: Sharing
	
	//Attempts to share the file with a given email
	func shareFile(_ email: String) {
		
		let permission = GTLRDrive_Permission.init()
		permission.emailAddress = email
		permission.type = "user"
		permission.role = "writer"
		
		let query = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: self.connectedUser.sheetInDrive)
		
		driveService.executeQuery(query, completionHandler: { (ticket, result, NSError) in
			if let error = NSError {
				print(error)
				self.connectedUser.shared = false
				self.trySharingAgain(email)
			} else {
				self.connectedUser.shared = true
			}
			self.updateList(self.connectedUser)
		})
		print("heyo")
	}
	
	
	
	
	
	//MARK: ConnectedUser Properties
	
	
	//Finds whether the sheet has been shared or not
	func findIfShared() {
		let query = GTLRDriveQuery_PermissionsList.query(withFileId: self.connectedUser.sheetInDrive)
		driveService.executeQuery(query) { (ticket, result, NSError) in
			if let error = NSError {
				print(error)
				
			} else {
				let list = result as! GTLRDrive_PermissionList
				
				if ((list.permissions!.count) <= 1) {
					
				} else {
					self.connectedUser.shared = true
				}
				self.updateList(self.connectedUser)
				print(self.connectedUser.shared)
			}
		}
	}
	
	//Finds the email address of the other user on this sheet
	func findSharedEmailInSheet() {
		let query = GTLRDriveQuery_PermissionsList.query(withFileId: self.connectedUser.sheetInDrive)
		query.fields = "permissions(emailAddress)"
		driveService.executeQuery(query) { (ticket, result, NSError) in
			if let error = NSError {
				print(error)
				
			} else {
				let list = result as! GTLRDrive_PermissionList
				
				if ((list.permissions!.count) == 0) {
					
				} else {
					for permission in list.permissions! {
						if (permission.emailAddress != GIDSignIn.sharedInstance()?.currentUser.profile.email) {
							self.connectedUser.email = permission.emailAddress!
						}
					}
					self.updateList(self.connectedUser)
					print(self.connectedUser.email)
				}
			}
		}
		
	}
	
	//Update the sum by fetching the cell from the sheet
	func updateSum() {
		let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: self.connectedUser.sheetInDrive, range: "Sheet1!P3")
		
		sheetsService.executeQuery(query) { (ticket, response, NSError) in
			if let error = NSError {
				print(error)
				
			} else {
				let result = response as! GTLRSheets_ValueRange
				
				self.connectedUser.sum = result.values![0][0] as! String
				
				
				if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
					if let homeView = tabBar.selectedViewController as? HomePageViewController {
						homeView.refresh()
					}
				}
				
				
				self.updateList(self.connectedUser)
			}
		}
	}
	
	//Checks the spreadsheet to see which user is first, or on the left. If the first user is the connected user
	// which is not the user of this device, then true.
	func findIfIsFirst() {
		let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: self.connectedUser.sheetInDrive, range: "Sheet1!A1")
		sheetsService.executeQuery(query) { (ticket, response, NSError) in
			if let error = NSError {
				print(error)
				
			} else {
				let result = response as! GTLRSheets_ValueRange
				
				if let cellVal = result.values![0][0] as? String {
					
					if cellVal == self.connectedUser.name {
						self.connectedUser.isFirst = true
					} else {
						self.connectedUser.isFirst = false
					}
					
					self.updateList(self.connectedUser)
					print(cellVal, "is first")
				}
			}
		}
	}
	
	
	//MARK: Sheet Data
	
	
	
	//Sets up a spreadsheet for the first time, setting up names of columns etc
	func firstTimeSetup() {
		
		var valueRange = GTLRSheets_ValueRange()
		valueRange.values = [[GIDSignIn.sharedInstance().currentUser.profile.givenName]]
		valueRange.range = "Sheet1!A1"
		
		var valueRange2 = GTLRSheets_ValueRange()
		valueRange2.values = [[self.connectedUser.name]]
		valueRange2.range = "Sheet1!H1"
		
		var valueRange3 = GTLRSheets_ValueRange()
		valueRange3.values = [["Item", "Price", "Date", "Notes", "Total", "=SUM(B4:B)"]]
		valueRange3.range = "Sheet1!A3:F3"
		
		var valueRange4 = GTLRSheets_ValueRange()
		valueRange4.values = [["Item", "Price", "Date", "Notes", "Total", "=SUM(I4:I)"]]
		valueRange4.range = "Sheet1!H3:M3"
		
		var valueRange5 = GTLRSheets_ValueRange()
		valueRange5.values = [["Sum", "=F3-M3"]]
		valueRange5.range = "Sheet1!O3:P3"
		
		
		let allValues = [valueRange, valueRange2, valueRange3, valueRange4, valueRange5]
		
		
		var batchUpdate = GTLRSheets_BatchUpdateValuesRequest()
		batchUpdate.data = allValues
		batchUpdate.valueInputOption = "USER_ENTERED"
		
		let query = GTLRSheetsQuery_SpreadsheetsValuesBatchUpdate.query(withObject: batchUpdate, spreadsheetId: self.connectedUser.sheetInDrive)
		
		sheetsService.executeQuery(query) { (ticket, response, NSError) in
			if let error = NSError {
				print(error)
				
			} else {
				let result = response as! GTLRSheets_BatchUpdateValuesResponse
				print(result.totalUpdatedCells as Any)
				if ((result.totalUpdatedCells as! Int) < 16) {
					
				}
				
				
				
				self.updateList(self.connectedUser)
			}
		}
	}
	
	
	
	//Adds a new entry to the spreadsheet under the current user's name
	
	func addNewEntry(_ item: String, _ price: String, _ date: String, _ notes: String) {
		
				var range: String
				if self.connectedUser.isFirst {
					range = "Sheet1!H3:K3"
				} else {
					range = "Sheet1!A3:D3"
				}
		
		
				var valueRange = GTLRSheets_ValueRange()
				valueRange.values = [[item, price, date, notes]]
				valueRange.majorDimension = "ROWS"
				valueRange.range = range
		
		
				var query = GTLRSheetsQuery_SpreadsheetsValuesAppend.query(withObject: valueRange, spreadsheetId: self.connectedUser.sheetInDrive, range: range)
		
				query.valueInputOption = "USER_ENTERED"
		
				self.sheetsService.executeQuery(query) { (ticket, response, NSError) in
					if let error = NSError {
						print (error)
						
					} else {
						
					}
				}
	}
	

	
	
	
	// MARK: Alerts
	
	//Present an alert asking whether the user has created a file before, or if they want to
	//make a new connection
	
	func choosePath() {
		let alert1 = UIAlertController(title: "Welcome!",
									   message: "Would you like to create a new Debt Connection or use an existing connection?",
									   preferredStyle: .alert)
		
		alert1.addAction(UIAlertAction(title: "Use Existing", style: .default, handler: { (_) in
			self.useExisting()
		}))
		alert1.addAction(UIAlertAction(title: "Create New", style: .default, handler: { (_) in
			self.createNew()
		}))

		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert1, animated: true, completion: nil)
	}
	
	//Then ask what the name of the person they share with is
	
	func useExisting() {
		let alert2 = UIAlertController(title: "Debt Connect",
									   message: "What is the name of the person you have previously connected with?",
									   preferredStyle: .alert)
		
		alert2.addTextField { (textField) in
		}
		
		alert2.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			let name = alert2.textFields![0].text!
			if name != "" {
				self.connectedUser.name = name
				self.findSheet(name)
			} else {
				self.findNameBlank()
			}
			
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert2, animated: true, completion: nil)
	}
	
	//Then ask what the name of the person they will share with is
	
	func createNew() {
		let alert3 = UIAlertController(title: "Debt Connect",
									   message: "What is the name of the person you want to connect with?",
									   preferredStyle: .alert)
		
		alert3.addTextField { (textField) in
		}
		
		alert3.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in
			self.choosePath()
		}))
		alert3.addAction(UIAlertAction(title: "Next", style: .default, handler: { (_) in
			let name = alert3.textFields![0].text!
			if name != "" {
				self.connectedUser.name = name
				self.enterEmail(name)
				self.updateList(self.connectedUser)
			} else {
				self.newNameBlank()
			}
			
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert3, animated: true, completion: nil)
	}
	
	
	//Then ask what the email is
	
	func enterEmail(_ name: String) {
		let alert4 = UIAlertController(title: "Debt Connect",
									   message: "Enter the email of " + name,
									   preferredStyle: .alert)
		
		alert4.addTextField { (textField) in
		}
		
		alert4.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in
			self.choosePath()
		}))
		alert4.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			let email = alert4.textFields![0].text!
			if email != "" {
				self.connectedUser.email = email
				self.createSheet(name, email)
				self.updateList(self.connectedUser)
			} else {
				self.newEmailBlank(name)
			}
			
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert4, animated: true, completion: nil)
	}
	
	
	
	
	
	
	// MARK: Error Alerts
	
	
	// If no sheet found for name, go back to the beginning
	
	func noSheetFound(_ name: String) {
		let alert5 = UIAlertController(title: "Debt Connect",
									   message: "No File Found for " + name,
									   preferredStyle: .alert)
		
		alert5.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			self.choosePath()
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert5, animated: true, completion: nil)
	}
	
	
	// If email fails to share, try again, or enter new email if entered wrong the first time
	
	func trySharingAgain(_ email: String) {
		let alert6 = UIAlertController(title: "Could Not Share With " + email,
									   message: "Enter a new email or leave blank to Try Again for the same email.",
									   preferredStyle: .alert)
		
		alert6.addTextField { (textField) in
		}
		
		alert6.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { (_) in
			let email = alert6.textFields![0].text!
			
			if email != "" {
				self.connectedUser.email = email
			}
			
			self.shareFile(self.connectedUser.email)
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert6, animated: true, completion: nil)
	}
	
	
	
	//If the user is finding a previous sheet and does not enter a name, ask for the name
	func findNameBlank() {
		let alert7 = UIAlertController(title: "Name was left blank",
									   message: "What is the name of the person you have previously connected with?",
									   preferredStyle: .alert)
		
		alert7.addTextField { (textField) in
		}
		
		alert7.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			let name = alert7.textFields![0].text!
			if name != "" {
				self.connectedUser.name = name
				self.findSheet(name)
			} else {
				self.findNameBlank()
			}
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert7, animated: true, completion: nil)
	}
	
	//If the user is creating a new sheet and does not enter a name, ask for the name
	func newNameBlank() {
		let alert8 = UIAlertController(title: "Name was left blank",
									   message: "What is the name of the person you have previously connected with?",
									   preferredStyle: .alert)
		
		alert8.addTextField { (textField) in
		}
		
		alert8.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			let name = alert8.textFields![0].text!
			if name != "" {
				self.connectedUser.name = name
				self.enterEmail(name)
				self.updateList(self.connectedUser)
			} else {
				self.newNameBlank()
			}
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert8, animated: true, completion: nil)
		
		
	}
	
	//If the user is creating a new sheet and does not enter an email, ask for the email
	func newEmailBlank(_ name: String) {
		let alert9 = UIAlertController(title: "Email was left blank",
									   message: "Enter the email of " + name,
									   preferredStyle: .alert)
		
		alert9.addTextField { (textField) in
		}
		
		alert9.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
			let email = alert9.textFields![0].text!
			if email != "" {
				self.connectedUser.email = email
				self.createSheet(name, email)
				self.updateList(self.connectedUser)
			} else {
				self.newEmailBlank(name)
			}
			
		}))
		
		var vc = UIApplication.shared.keyWindow?.rootViewController
		if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
			vc = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
		}
		vc?.present(alert9, animated: true, completion: nil)
		
	}
	
}
