//
//  RecordDBHelper.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

struct RecordDBHelper {
      
    //Fetches data from API.
    func fetchData(completion: @escaping (Result<AdministrationResponseDB, Error>) -> Void) {
        let urlString = "https://covid-vaccinatie.be/api/v1/administered.json"
        
        guard let recordsURL = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: recordsURL) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("API status: \(httpResponse.statusCode)")
            }
            guard let validData = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let records = try decoder.decode(AdministrationResponseDB.self, from: validData)
                completion(.success(records))
            } catch let serializationError {
                completion(.failure(serializationError))
            }
        }
        task.resume()
    }
}
