//
//  Books-Model.swift
//  IZA-MVC-1
//
//  Created by Martin Hruby on 13/03/2020.
//  Copyright © 2020 Martin Hruby FIT. All rights reserved.
//

import Foundation
import UIKit


// ---------------------------------------------------------------------
// Datovy zaznam o knize
// ---------------------------------------------------------------------
struct Book  {
    // -----------------------------------------------------------------
    // datove atributy
    var title: String = ""
    var author: String = ""
    var yearOfPublishing = 1970
    
    // zaznam lze povazovat za platny, pokud...
    var isValid: Bool { title.count > 0 && author.count > 0 }
    
    // -----------------------------------------------------------------
    // pripadny volitelny obrazek prebalu knihy
    var cover: UIImage?
    // place-holder z projektu
    static let __coverPlaceHolder = UIImage(named: "pejsek.jpg")
    // vrat nejaky obrazek pro prezentaci
    var coverToShow: UIImage? { cover ?? Book.__coverPlaceHolder }
    
    // -----------------------------------------------------------------
    //
    init(title: String, author: String, year: Int) {
        //
        self.title = title; self.author = author
        self.yearOfPublishing = year
    }
    
    //
    static func demos() -> [Book] {
        //
        return [ Book(title: "Honzikova cesta", author: "Bohumil Riha",
                      year: 1234), Book(title: "Robinson Crusoe", author: "Daniel Defoe", year: 1235)]
    }
    
    //
    static func empty() -> Book {
        //
        return Book(title: "", author: "", year: 0)
    }
}

