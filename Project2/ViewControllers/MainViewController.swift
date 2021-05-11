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
        let moc = persistentContainer.viewContext
        moc.perform {
            let administrationRecord = AdministrationRecord(context: moc)
            let helper = RecordDBHelper()
            helper.fetchData { (response) in
                switch response {
                    case .success(let data):
                        guard let recordsArray = data.result["administered"] else { return }
                        for record in recordsArray {
                            moc.persist {//there seems to be an issue with persist function
                                administrationRecord.date = record.administrationDate
                                administrationRecord.firstDose = record.firstDose
                                administrationRecord.firstDose = record.secondDose
                                administrationRecord.region = record.region
                            }
                        }
                    case .failure(let error):
                        print(error)
                }
            }

            do {
              try moc.save()
            } catch {
              moc.rollback()
            }
        }
    }
    
//    func saveAdministrationRecords() {
//        let moc = persistentContainer.viewContext
//        moc.perform {
//            let administrationRecord = AdministrationRecord(context: moc)
//            let helper = RecordDBHelper()
//            helper.fetchData { (response) in
//                switch response {
//                    case .success(let data):
//                        guard let recordsArray = data.result["administered"] else { return }
//                        for record in recordsArray {
//                            moc.persist {
//                                administrationRecord.date = record.administrationDate
//                                administrationRecord.firstDose = record.firstDose
//                                administrationRecord.firstDose = record.secondDose
//                                administrationRecord.region = record.region
//                            }
//                        }
//                    case .failure(let error):
//                        print(error)
//                }
//            }
//
//            do {
//              try moc.save()
//            } catch {
//              moc.rollback()
//            }
//        }
//    }
}

