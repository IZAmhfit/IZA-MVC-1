//
//  ArrayDataSource.swift
//  IZA-MVC-1
//
//  Created by Martin Hruby on 13/03/2020.
//  Copyright © 2020 Martin Hruby FIT. All rights reserved.
//

import Foundation
import UIKit


// ---------------------------------------------------------------------
// Kody pokynu pro delegata tohodle data sourcu
// Pozn.: naprosto stejnym zpusobem bude komandovat
// NSFetchedResultsController sveho delegata (uvidime v CoreData DB)
enum ArrayTableSourceOperation {
    // zahaj editaci sveho obsahu, ukonci editaci sveho obsahu
    case beginUpdates, endUpdates
    // elementarni ukony
    case addRow, deleteRow, updateRow
}

// ---------------------------------------------------------------------
// komunikacni protokol delegata
// komunikaci pres protokol volime, kdyz ocekavame vetsi transfer dat
// smerem k delegatovi, tj. neni to pouze jedna akce...
// ...
// chci, aby protokol smela implementovat pouze trida
// (tj. ne struct/enum)
protocol ArrayTableSourceDelegate : class {
    // udelej cisty reload
    func arrayTableSourceGeneralUpdate();
    // vykonavej instrukce
    func arrayTableSource(operation: ArrayTableSourceOperation, atIndex: Int?);
}


// ---------------------------------------------------------------------
// pozadavky na zaznam, aby byl organizovatelny timto "array-data-sourcem"
protocol ArrayTableSourceElement {
    // s protokolem asociuji typ, v nasem pripade treba Book
    associatedtype CellElement
    
    // pro ucely tableView.dequeue...
    static var tableCellPrototype: String { get }
    
    // rikam cili, aby se zkonfiguroval z daneho zaznamu
    func selfConfig(with: CellElement);
}


// ---------------------------------------------------------------------
// Sablonovy typ pro:
// 1) uchovani zaznamu nejakeho typu
// 2) prezentaci jako dataSource tabulky
// ---------------------------------------------------------------------
// Musim odvozovat od NSObject, nebot protokol UITableViewDataSource vyzaduje
// nekoho, kdo implementuje NSObjectProtocol, coz NSObject typicky je
class ArrayTableSource<CellPrototype: ArrayTableSourceElement> : NSObject, UITableViewDataSource
{
    // typova zkratka, bude to typ, ktery mi urci ten, kdo bude
    // implementovat ArrayTableSourceElement
    typealias Cells = [CellPrototype.CellElement]
    
    // -----------------------------------------------------------------
    // inicializuji mutable pole zaznamu. Primitivni podoba existence dat.
    var _listOfElements = Cells()
    
    // -----------------------------------------------------------------
    // delegat formou protokolu
    // zopakujme si:
    // 1) delegata vzdy drzime jako weak (on tento objekt typicky vlastni,
    // takze rozpojujeme referencni cyklus)
    // 2) drzeni reference typu weak vyzaduje optional type
    // (pripoustime, ze muze dojit k vynulovani hodnoty)
    weak var delegate: ArrayTableSourceDelegate?
    
    // -----------------------------------------------------------------
    // konstrukce s nejakym pocatecnim obsahem
    init(initialContent: Cells) {
        //
        _listOfElements = initialContent
    }
    
    // -----------------------------------------------------------------
    // volej delegata pro elementarni pokyny, predpokladame jednotlive
    func withUpdates(_ op: ArrayTableSourceOperation, at: Int?) {
        // ... pokud delegat neni
        guard let _del = delegate else {
            //
            return ;
        }
        
        // Grand Central Dispatch, blok vkladame asynchronne do
        // fronty hlavniho vlakna, tj. provede se nekdy v budoucnu
        DispatchQueue.main.async {
            //
            _del.arrayTableSource(operation: .beginUpdates, atIndex: nil)
            _del.arrayTableSource(operation: op, atIndex: at)
            _del.arrayTableSource(operation: .endUpdates, atIndex: nil)
        }
    }
    
    // -----------------------------------------------------------------
    // vkladani prvku...
    func add(anItem: CellPrototype.CellElement) {
        // primitivni operace
        _listOfElements.append(anItem)
        
        // nove vznikly index do pripadne tabulky
        let _addIndx = _listOfElements.count - 1
        
        // asynchronni volani (kapitola o GCD)
        withUpdates(.addRow, at: _addIndx)
    }
    
    // -----------------------------------------------------------------
    // ...
    func replace(anItem: CellPrototype.CellElement, at: Int) {
        // kriticka chyba programu
        assert(at >= 0 && at < _listOfElements.count)
        
        // primitivni datova operace
        _listOfElements[at] = anItem
        
        // asynchronni volani (kapitola o GCD)
        withUpdates(.updateRow, at: at)
    }
    
    // -----------------------------------------------------------------
    // ...
    func delete(anItem: CellPrototype.CellElement, at: Int) {
        // kriticka chyba programu
        assert(at >= 0 && at < _listOfElements.count)
        
        // primitivni datova operace
        _listOfElements.remove(at: at)
        
        // asynchronni volani (kapitola o GCD)
        withUpdates(.deleteRow, at: at)
    }
    
    // -----------------------------------------------------------------
    // 1) UITableViewDataSource API - kolik sekci ma tabulka mit
    func numberOfSections(in tableView: UITableView) -> Int {
        //
        return 1
    }
    
    // -----------------------------------------------------------------
    // 2) kolik radku ma mit zadana sekce
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int
    {
        //
        return _listOfElements.count
    }
    
    // -----------------------------------------------------------------
    // 3) zkonstruuj bunku
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // dostavam objekt nejake UITableViewCell
        let _cell = tableView.dequeueReusableCell(withIdentifier: CellPrototype.tableCellPrototype, for: indexPath)
        
        // kde predpokladam, ze prototyp bunky implementuje muj
        // pozadovany protokol, proto lze provest pretypovani
        if let __cell = _cell as? CellPrototype {
            // prototypu bunky rikam, necht se laskave konfiguruje
            // ze zadanych dat
            __cell.selfConfig(with: _listOfElements[indexPath.row])
        }
        
        //
        return _cell
    }
}


// ---------------------------------------------------------------------
// Vsimneme si, ze ArrayTableSource pracuje s tabulkou, ale
// nedrzi si zadnou formu na tabulku referenci
// Muzeme to jeste vice zautomatizovat na specifictejsi objekt
// ---------------------------------------------------------------------
// Tato trida rozsiruje
class TableArrayDataSource<CellPrototype: ArrayTableSourceElement>: ArrayTableSource<CellPrototype>, ArrayTableSourceDelegate
{
    // uz si tabulku podrzim, ovsem weakly
    weak var _table: UITableView?
    
    // -----------------------------------------------------------------
    // konstrukce s nejakym pocatecnim obsahem
    init(initialContent: Cells, andTable: UITableView) {
        //
        _table = andTable
        
        //
        super.init(initialContent: initialContent)
        
        //
        delegate = self
    }
    
    // -----------------------------------------------------------------
    //
    func arrayTableSourceGeneralUpdate() {
        //
        _table?.reloadData()
    }
    
    //
    func arrayTableSource(operation: ArrayTableSourceOperation, atIndex: Int?)
    {
        guard let tableView = _table else { return }
        
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
}
