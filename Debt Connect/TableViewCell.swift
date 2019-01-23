//
//  TableViewCell.swift
//  Debt Connect
//
//  Created by Brandon Starcheus on 1/6/19.
//  Copyright © 2019 Brandon Starcheus. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

	//MARK: Properties
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var emailLabel: UILabel!
	
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
