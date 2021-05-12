//
//  PersistenceHelper.swift
//  Project2
//
//  Created by mathieu on 12/05/2021.
//

import Foundation
import CoreData

struct PersistenceHelper {
    
    var persistentContainer: NSPersistentContainer!
    
    func batchInsertAdministrationRecords(administrationRecords: [AdministrationRecordDB]) {
        guard !administrationRecords.isEmpty else { return }
        //let moc = persistentContainer.viewContext
        persistentContainer.performBackgroundTask({ (moc) in
            let batchInsert = self.batchInsertRequest(administrationRecords: administrationRecords)
            do {
                try moc.execute(batchInsert)
            } catch {
                moc.rollback()
            }
        })
    }
    
    func batchInsertRequest(administrationRecords: [AdministrationRecordDB]) -> NSBatchInsertRequest {
        var index = 0
        let total = administrationRecords.count
        
        let batchInsert = NSBatchInsertRequest(
            entity: AdministrationRecord.entity()) { (managedObject: NSManagedObject) -> Bool in
            
            guard index < total else { return true }
            
            if let record = managedObject as? AdministrationRecord {
                let data = administrationRecords[index]
                record.date = data.administrationDate
                record.firstDose = data.firstDose
                record.firstDose = data.secondDose
                record.region = data.region
            }
            
            
            index += 1
            return false
        }
        return batchInsert
    }
}

