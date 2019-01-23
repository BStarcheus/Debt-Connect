//
//  ConnectedUser.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 1/6/19.
//  Copyright © 2019 Brandon Starcheus. All rights reserved.
//
import os.log


class ConnectedUser: NSObject, NSCoding {
	var name: String
	var email: String
	var shared: Bool
	var sheetInDrive: String
	var sum: String
	var isFirst: Bool
	
	
	
	init(_ name: String, _ email: String, _ shared: Bool, _ sheetInDrive: String, _ sum: String, _ isFirst: Bool) {
		self.name = name
		self.email = email
		self.shared = shared
		self.sheetInDrive = sheetInDrive
		self.sum = sum
		self.isFirst = isFirst
	}
	
	
	// MARK: NSCoding
	
	struct PropertyKey {
		static let name = "name"
		static let email = "email"
		static let shared = "shared"
		static let sheetInDrive = "sheetInDrive"
		static let sum = "sum"
		static let isFirst = "isFirst"
	}
	
	static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
	static let ArchiveURL = DocumentsDirectory.appendingPathComponent("connectedUsers")
	
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(name, forKey: PropertyKey.name)
		aCoder.encode(email, forKey: PropertyKey.email)
		aCoder.encode(shared, forKey: PropertyKey.shared)
		aCoder.encode(sheetInDrive, forKey: PropertyKey.sheetInDrive)
		aCoder.encode(sum, forKey: PropertyKey.sum)
		aCoder.encode(isFirst, forKey: PropertyKey.isFirst)
	}
	
	required convenience init?(coder aDecoder: NSCoder) {
		guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
			os_log("Unable to decode the name of the connected user.", log: OSLog.default, type: .debug)
			return nil
		}
		guard let email = aDecoder.decodeObject(forKey: PropertyKey.email) as? String else {
			os_log("Unable to decode the email of the connected user.", log: OSLog.default, type: .debug)
			return nil
		}
		let shared = aDecoder.decodeBool(forKey: PropertyKey.shared)
		guard let sheetInDrive = aDecoder.decodeObject(forKey: PropertyKey.sheetInDrive) as? String else {
			os_log("Unable to decode the sheetID of the connected user file.", log: OSLog.default, type: .debug)
			return nil
		}
		guard let sum = aDecoder.decodeObject(forKey: PropertyKey.sum) as? String else {
			os_log("Unable to decode the sum of the connected user file.", log: OSLog.default, type: .debug)
			return nil
		}
		let isFirst = aDecoder.decodeBool(forKey: PropertyKey.isFirst)
		
		self.init(name, email, shared, sheetInDrive, sum, isFirst)
	}
	
	
}


