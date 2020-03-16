//
//  MojeTable.swift
//  IZA-MVC-1
//
//  Created by Martin Hruby on 13/03/2020.
//  Copyright © 2020 Martin Hruby FIT. All rights reserved.
//

import Foundation
import UIKit


// ---------------------------------------------------------------------
// Trida pro prototyp bunky tabulky
// - dedi z UITableViewCell, pac je to bunka tabulky
// - implementuje ArrayTableSourceElement, aby fungovala rizena z
// ArrayTableSource
class BookTableViewCell: UITableViewCell, ArrayTableSourceElement {
    // -----------------------------------------------------------------
    // specifikuje asociovany typ v ArrayTableSourceElement
    typealias CellElement = Book
    
    // -----------------------------------------------------------------
    // veci z interface-builderu (SB)
    @IBOutlet var cover: UIImageView?
    @IBOutlet var author: UILabel?
    @IBOutlet var title: UILabel?
    @IBOutlet var year: UILabel?
    
    // -----------------------------------------------------------------
    // identifikator prototypu ze StoryBoardu
    static var tableCellPrototype: String { "BookBasicCell" }
    
    // -----------------------------------------------------------------
    // sebe-konfigurace
    func selfConfig(with: Book) {
        //
        cover?.image = with.coverToShow
        
        //
        author?.text = with.author
        title?.text = with.title
        year?.text = String(with.yearOfPublishing)
    }
}


// ---------------------------------------------------------------------
// TableViewController - je UIViewController, ktery vlastni view
// typu TableView a soucasne tabulce implementuje/dodava rozhrani
// dataSource (UITableViewDataSource) a delegate (UITableViewDelegate)
// ---------------------------------------------------------------------
class MojeTableVC: UITableViewController, ArrayTableSourceDelegate {
    // -----------------------------------------------------------------
    // ve viewDidLoad() si instancuju dataSource pro moji tabulku
    // udelam to urcite, proto si smim dovolit dat datovy typ !
    var _myDataSource: ArrayTableSource<BookTableViewCell>!
    
    // -----------------------------------------------------------------
    // Pro umisteni tlacitek je vhodne, aby VC byl zapouzdren do
    // NavigationVC
    // - storyboard - menu - Editor - EmbedIn - Navigation
    // -----------------------------------------------------------------
    // Demo instanciace obrazovky ze SB a jeji "rucni" spusteni
    // alternativne lze v SB konfigurovat segue
    @IBAction func tlacitkoZeStoryBoardu() {
        // pristup na SB pod jmenem "Main"
        // application bundle je "default", tj. ==nil
        let _sb = UIStoryboard(name: "Main", bundle: nil)
        
        // ze SB si instancuji zadany VC + conditional pretypovani na cilovy typ
        if let _vc = _sb.instantiateViewController(identifier: "bookDetailVC") as? BookDetailVC
        {
            // novy zaznam pro knizku
            _vc.inBook = Book.empty()
            _vc.doWhenEnding = detailAcceptResponse(_:)
            
            // load+run view-controlleru
            // !!! VC se spousti "modal" stylem, tj. mimo ramec
            // implicitniho NavigationVC, tj. chybi horni lista
            present(_vc, animated: true)
        }
    }
    
    // -----------------------------------------------------------------
    // delegatstvi z BookDetailVC neresim pres protokol, ale zadanim
    // reference na tuto instancni funkci (muzu ji drzet jako closure)
    // -----------------------------------------------------------------
    // Pozn.: zpravy predavam do Modelu. Model pak automaticky
    // vola tento VC s aktualizacemi View
    func detailAcceptResponse(_ input: BookDetailVCResponse) {
        // vysledky z BookDetailVC
        switch input {
            // objekt se ma aktualizovat
        case let .saved(object: _obj, at: _idx):
            //
            _myDataSource.replace(anItem: _obj, at: _idx.row)
            // Swift!!! "break" je zde implicitni!!!
        case let .created(object: _obj):
            //
            _myDataSource.add(anItem: _obj)
            
        case let .deleted(object: _obj, at: _idx):
            //
            _myDataSource.delete(anItem: _obj, at: _idx.row)
            
        default:
            // () je na oblbnuti kompileru...takhle se zadava
            // "prazdna akce"
            // pozn.: "default" nemusi byt, pokud je "case"
            // reseno vycerpavajicicm zpusobem (vsechny pripady)
            ()
        }
    }
    
    // -----------------------------------------------------------------
    // pripominam zivotni cyklus ViewControlleru:
    // - po nacteni obsahu (typicky ze Storyboardu) se dostava
    // do stavu "loaded" a aktivuje se tato metoda
    // - moznost do VC doplnit dalsi prvky
    // -- tlacitka
    // -- nastartovat DB dotazy
    // -- spustit procesy/operace
    override func viewDidLoad() {
        // 1) volam nadrazenou obsluhu udalosti
        super.viewDidLoad()
        
        // 2) instancuju datasource tabulky
        _myDataSource = ArrayTableSource(initialContent: Book.demos())
        _myDataSource.delegate = self
        
        // 3) datasource provazu na tabulku
        tableView.dataSource = _myDataSource
    }
    
    // -----------------------------------------------------------------
    // delegatstky protokol z array-datasource
    func arrayTableSourceGeneralUpdate() {
        //
        tableView.reloadData()
    }
    
    // -----------------------------------------------------------------
    // volani z array-datasource
    func arrayTableSource(operation: ArrayTableSourceOperation, atIndex: Int?) {
        //
        switch operation {
        case .beginUpdates:
            tableView.beginUpdates()
        case .endUpdates:
            tableView.endUpdates()
        case .addRow:
            tableView.insertRows(at: [IndexPath(row: atIndex!, section: 0)],
                                 with: .fade)
        case .deleteRow:
            tableView.deleteRows(at: [IndexPath(row: atIndex!, section: 0)],
                                 with: .fade)
        case .updateRow:
            tableView.reloadRows(at: [IndexPath(row: atIndex!, section: 0)],
                                 with: .fade)
        }
    }
     
    // -----------------------------------------------------------------
    // prechod na detial pri kliknuti na bunku tabulky je v SB zadan
    // jako segue, tj. zpracujme tento segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segue
        // 1) cilovym VC je BookDetailVC
        if let _detailVC = segue.destination as? BookDetailVC {
            // 2) kontroluju id daneho segue
            // 3) musi byt oznaceny nejaky radek tabulky
            if segue.identifier == "bookShowDetail", let _row = tableView.indexPathForSelectedRow
            {
                // !!! zdurazneme, ze v tomto okamziku jeste neni
                // VC "loaded", mam ho pouze instancovany
                // tj. jeho IBOutlets jsou nil
                // zapisuju do instancnich dat ne-IBOutletoveho typu
                _detailVC.inBook = _myDataSource._listOfElements[_row.row]
                // zadam index-path, cimz se odlisuju od "insert" new
                _detailVC.bookIndexPath = _row
                // jako delegata davam sebe, closure na tuto fci
                _detailVC.doWhenEnding = detailAcceptResponse(_:)
            }
        }
    }
}
