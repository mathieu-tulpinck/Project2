//
//  APIResponse.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

//Both structs hereunder conform to the Codable protocol in order to be used by instance of JSONDecoder.
struct AdministrationResponseAPI: Decodable {
    let result: [String: [AdministrationRecordAPI]]
}

struct AdministrationRecordAPI: Decodable {
    let date: String
    let firstDose: Int32
    let secondDose: Int32
    let region: String?//This value can be null, namely in the event of vaccination administrations not linked to a particular region.
}




