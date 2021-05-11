//
//  ViewController.swift
//  Project2
//
//  Created by mathieu on 08/05/2021.
//

import UIKit

class ViewController: UIViewController {
    
//    func saveData() {
//
//        let helper = RecordDBHelper()
//
//
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let helper = RecordDBHelper()
        helper.fetchData { (result) in
            switch result {
                case .success(let records):
                    print("\(records)\n")
                case .failure(let error):
                    print(error)
            }
        }
    }
}

