//
//  NSPersistentContainer.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation
import CoreData

extension NSPersistentContainer {
  
    //Implementation recommended in ALEBICTO Mario Eguiluz , BARKER Chris, WALS Donny, Mastering iOS 14 Programming - Fourth Edition, 2021, Packt: chapters 8-9.
    func saveContextIfNeeded() {
    if viewContext.hasChanges {
      do {
        try viewContext.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}
