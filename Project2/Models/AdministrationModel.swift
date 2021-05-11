//
//  Administration.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

struct AdministrationResponse: Decodable {
    let result: [String: [AdministratorRecord]]
}

struct AdministratorRecord: Decodable {
    let date: String
    var administrationDate: Date? {
        return DateFormatter().date(from: date)
    }
    let firstDose: Int
    let secondDose: Int
    let region: String?
}




