//
//  NSPersistentContainer.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation
import CoreData

extension NSPersistentContainer {
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
