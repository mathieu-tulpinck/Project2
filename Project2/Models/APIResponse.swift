//
//  APIResponse.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

struct AdministrationResponseAPI: Decodable {
    let result: [String: [AdministrationRecordAPI]]
}

struct AdministrationRecordAPI: Decodable {
    let date: String
    let firstDose: Int32
    let secondDose: Int32
    let region: String?
}




