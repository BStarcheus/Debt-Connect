//
//  ConnectedUsersTableViewController.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 1/6/19.
//  Copyright © 2019 Brandon Starcheus. All rights reserved.
//

import UIKit
import os.log


class ConnectedUsersTableViewController: UITableViewController, ConnectedUserAPI {

	var sheetsAPI: SheetsAPI?
	
	func getAPI() -> SheetsAPI? {
		return self.sheetsAPI
	}
	func setAPI(_ api: SheetsAPI?) {
		if (api != nil) {
			self.sheetsAPI = api
		}
	}
	
	var connectedUsers = [ConnectedUser]()
	
	@IBOutlet weak var cancelButton: UIBarButtonItem!
	
	
	
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if let saved = self.sheetsAPI?.loadConnectedUsers() {
			connectedUsers = saved
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let tempList = sheetsAPI?.loadConnectedUsers(), tempList.count > 0 {
		} else {
			if sheetsAPI?.connectedUser.name == "" && sheetsAPI?.connectedUser.sheetInDrive == "" {
				sheetsAPI?.choosePath()
				print("tried to choose")
			}
		}
		
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return connectedUsers.count
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellIdentifier = "TableViewCell"
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TableViewCell
			else {
				fatalError("The dequed cell is not an instance of TableViewCell")
		}

        let connectedUser = connectedUsers[indexPath.row]
		
		print(connectedUser.name)
		print(connectedUser.email)
		print(connectedUsers[indexPath.row].name)
		print(connectedUsers[indexPath.row].email)
		print(sheetsAPI?.connectedUser.sheetInDrive as Any)
		print(sheetsAPI?.connectedUser.email as Any)
		
		cell.nameLabel.text = connectedUser.name
		cell.emailLabel.text = connectedUser.email

        return cell
    }
	

	
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
	

	
    // Override to support editing the table view.
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            connectedUsers.remove(at: indexPath.row)
			
			sheetsAPI?.connectedUser = ConnectedUser("", "", false, "", "", false)
			
			self.sheetsAPI?.saveConnectedUsers(connectedUsers)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
	

	
	/*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
	

	
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
	*/
	

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
		
		if let pressedRow = sender as? TableViewCell {
			sheetsAPI?.connectedUser = connectedUsers[(tableView.indexPath(for: pressedRow)?.row)!]
			sheetsAPI?.updateList((sheetsAPI?.connectedUser)!)
		}
		
    }
	
	//MARK: Actions
	
	
	
	@IBAction func cancelButton(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
	
	
	@IBAction func addConnectedUser(_ sender: UIBarButtonItem) {
		sheetsAPI?.choosePath()
	}
	
}
