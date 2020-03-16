//
//  General-VCs.swift
//  IZA-MVC-1
//
//  Created by Martin Hruby on 13/03/2020.
//  Copyright © 2020 Martin Hruby FIT. All rights reserved.
//

import Foundation
import UIKit


// ---------------------------------------------------------------------
//
class StringEditTableViewCell: UITableViewCell {
    //
    @IBOutlet var lab: UILabel?
    @IBOutlet var textValue: UITextField?
    
    //
    func load(from: String) {
        //
        textValue?.text = from
    }
}
