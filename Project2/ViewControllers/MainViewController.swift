//
//  MainViewController.swift
//  Project2
//
//  Created by mathieu on 08/05/2021.
//

import UIKit
import CoreData

class MainViewController: UIViewController {
    
    var persistentContainer: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let data = getData()
        saveData(data: data)
    
    }
    
    func getData() -> [AdministrationRecordDB] {
        let helper = FetchDataHelper()
        var data: [AdministrationRecordDB] = []
        helper.fetchData { (response) in
            switch response {
                case .success(let returnedData):
                    guard let recordsArray = returnedData.result["administered"] else { return }
                    data = recordsArray
                case .failure(let error):
                    print(error)
            }
        }
        
        return data
    }
    
    func saveData(data: [AdministrationRecordDB]) {
        let helper = PersistenceHelper()
        helper.batchInsertAdministrationRecords(administrationRecords: data)
    }
}



