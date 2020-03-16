//
//  Book-Detail-VC.swift
//  IZA-MVC-1
//
//  Created by Martin Hruby on 13/03/2020.
//  Copyright © 2020 Martin Hruby FIT. All rights reserved.
//

import Foundation
import UIKit


// ---------------------------------------------------------------------
// navratova hodnota z BookDetailVC
enum BookDetailVCResponse {
    //
    case deleted(object: Book, at: IndexPath)
    case saved(object: Book, at: IndexPath)
    case created(object: Book)
    case actionCancelled
}

// ---------------------------------------------------------------------
// delegat ve forme jednoho closure bude mit tento format:
// cteme: funkce s parametrem ... vracejici Void
typealias BookDetailVCDelegate = (BookDetailVCResponse) -> ()

// ---------------------------------------------------------------------
// Jeden ze zpusobu transformace ze tri text-field na nove vznikajici
// zaznam Book
extension Book {
    // -----------------------------------------------------------------
    // Pripomenme si: init? je konstrukce objektu, ktera muze
    // "havarovat" a vysledkem je nil
    init?(atf: UITextField?, ttf: UITextField?, ytf: UITextField?) {
        // test1: vsechny outlety jsou not-nil
        guard let _atf = atf, let _ttf = ttf, let _ytf = ytf else {
            //
            return nil
        }
        
        // test2: jejich obsahy jsou not-nil
        guard let __atf = _atf.text, let __ttf = _ttf.text, let __ytf = _ytf.text else {
            //
            return nil
        }
        
        // test3: rok (cislo) lze uspesne transformovat na Int
        guard let __year = Int(__ytf) else {
            //
            return nil
        }
        
        // konstrukce zaznamu
        self.title = __ttf
        self.author = __atf
        self.yearOfPublishing = __year
        self.cover = nil
    }
}

// ---------------------------------------------------------------------
// VC pro detail nad zaznamem Book
// jako veskery vertikalne organizovany obsah je implementovan tabulkou
// ---------------------------------------------------------------------
// Tabulka je ve SB se zadanym STATIC obsahem, tj. nepotrebuje
// dodatecny dataSource.
class BookDetailVC: UITableViewController {
    // -----------------------------------------------------------------
    // vstupni hodnota zaznamu, vzdy existuje
    var inBook: Book!
    // vstupni hodnota indexPath (z tabulky), pokud bylo predano
    var bookIndexPath: IndexPath?
    // optional, akce pri ukoncovani VC
    var doWhenEnding: BookDetailVCDelegate?
    
    // -----------------------------------------------------------------
    // ve SB si beru zkratky (ref) na staticke bunky tabulky
    @IBOutlet var cellAuthor: StringEditTableViewCell?
    @IBOutlet var cellTitle: StringEditTableViewCell?
    @IBOutlet var cellYear: StringEditTableViewCell?
    @IBOutlet var cellBookCover: UIImageView?
    
    // transformu soucasne View na zaznam Book
    var asBook: Book? {
        //
        Book(atf: cellAuthor?.textValue,
             ttf: cellTitle?.textValue, ytf: cellYear?.textValue)
    }
    
    // -----------------------------------------------------------------
    // presun dat z modelu do Views
    // macOS - bylo by reseno "bindings", v iOS bohuzel nelze
    func loadUIFromModel() {
        //
        cellAuthor?.load(from: inBook.author)
        cellTitle?.load(from: inBook.title)
        cellYear?.load(from: String(inBook.yearOfPublishing))
        
        //
        cellBookCover?.image = inBook.coverToShow
    }
    
    // -----------------------------------------------------------------
    // presun hodnot z views -> model
    func saveUIToModel() -> Book? {
        //
        guard var _nb = asBook else { return nil }
        
        // jenom zkopiruju cover z inBook.
        _nb.cover = inBook.cover; return _nb
    }
    
    // -----------------------------------------------------------------
    // ukonceni tohoto VC dvema moznymi zpusoby
    // - pokud je integrovan do NVC, pak pop
    // - jinak dismiss
    func endIt(_ result: BookDetailVCResponse) {
        // -------------------------------------------------------------
        // self.navigationController != nil POKUD je tento VC zapouzdren
        // do NavigationVC
        if let _nvc = navigationController {
            // poslani zpravy NVC rika "zrus tento VC a vrat rizeni
            // na predchozi"
            _nvc.popViewController(animated: true)
            
            // a na konec fronty prace hlavniho vlakna dej...
            DispatchQueue.main.async {
                // poslani zpravy do predchoziho VC
                self.doWhenEnding?(result)
            }
        } else {
            // rusim modalne prezentovany self-VC, rizeni se preda
            // na predchozi VC
            dismiss(animated: true) { self.doWhenEnding?(result) }
        }
        
        // -------------------------------------------------------------
        // pozn: vsimneme si hlavicky
        // func dismiss(animated flag: Bool, completion: (() -> Void)? = nil)
        // completion je closure, ktery se spusti az po vraceni rizeni
        // na predchozi VC
        // idealne zde predavat vysledky do predchoziho VC
        // NVC.pop(...) toto neumoznuje, tudiz delame jinak...
        // -------------------------------------------------------------
        // v cem je vlastne problem??
        // - potrebuju predat data do predchoziho VC jako zpravu,
        // ktera u nej vyvola zmenu View...vlozit radek, smazat...apod
        // - k tomu ucelu musi ten prechozi VC uz byt VIDITELNY
        // - viditelnym se stane, az po nekolika krocich (RunLoop)
        // - tedy je vlastne davam do fronty zpravu, ktera se ma spustit,
        // az se ten predchozi VC ukaze
        // -------------------------------------------------------------
        // v podstate mu muzu poslat datovou zpravu, on si ji ulozi,
        // a podiva se na ni pri svem viewDidAppear...
        // ...takovy pristup je vsak velmi velmi velmi pochybny
    }
    
    // -----------------------------------------------------------------
    // stisteno tlacitko save, tj. chci data ulozit do DB a ukoncit detail
    @objc func tlacitkoSave() {
        // 1) presun data z Views do zaznamu objektu
        // pokud data nejsou platna, prerus ukoncovani VC
        guard let _savedInfo = saveUIToModel() else {
            //
            return
        }
        
        // 2) vystupni zaznam je OK
        if _savedInfo.isValid {
            // 2a) pokud mam not-nil indexPath, tam jsem byl volan
            // z tabulky, tj. pracuju nad existujicim zaznamem
            if let _ipath = bookIndexPath {
                // 2b) ... vysledek tudiz hlasim jako save-update
                endIt(.saved(object: _savedInfo, at: _ipath))
            } else {
                // 2c) jinak vysledek hlasim jako save-insert
                endIt(.created(object: _savedInfo))
            }
        }
    }

    // -----------------------------------------------------------------
    // bylo dokonceni nacitani obsahu VC (Views)
    override func viewDidLoad() {
        //
        super.viewDidLoad()
        
        // pokud jsem v NVC, pak predefinuju <XXX tlacitko vlevo
        if let _ = navigationController {
            //
            let _saveb = UIBarButtonItem(barButtonSystemItem: .save, target: self,
                                         action: #selector(tlacitkoSave))
            
            // nastav leve horni tlacitko, akce je "save"
            navigationItem.leftBarButtonItem = _saveb
        }
        
        // inicializuj obsah IBOutlets z modelu
        loadUIFromModel()
    }
    
    // -----------------------------------------------------------------
    // odchytnuti selekce bunky v tableview
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath)
    {
        // zajima me pouze sekce 2
        guard indexPath.section == 2 else {
            //
            return
        }
        
        //
        switch indexPath.row {
        case 0:
            //
            tlacitkoSave()
            
        case 1:
            // delete je platny pouze pokud byl definovan index
            if let _ip = bookIndexPath {
                //
                endIt(.deleted(object: inBook, at: _ip))
            }
            
        case 2:
            //
            endIt(.actionCancelled)
            
        default:
            //
            ()
        }
    }
}

