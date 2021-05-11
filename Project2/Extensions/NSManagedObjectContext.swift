//
//  NSManagedObjectContext.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import CoreData

extension NSManagedObjectContext {
  func persist(block: @escaping () -> Void) {
    perform {

      block()

      do {
        try self.save()
      } catch {
        self.rollback()
      }
    }
  }
}
