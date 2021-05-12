//
//  APIResponse.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

struct AdministrationResponseDB: Decodable {
    let result: [String: [AdministrationRecordDB]]
}

struct AdministrationRecordDB: Decodable {
    let date: String
    var administrationDate: Date? {
        return DateFormatter().date(from: date)
    }
    let firstDose: Int32
    let secondDose: Int32
    let region: String?
}




