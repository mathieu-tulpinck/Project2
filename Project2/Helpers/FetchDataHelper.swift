//
//  FetchDataHelper.swift
//  Project2
//
//  Created by mathieu on 11/05/2021.
//

import Foundation

struct FetchDataHelper {
      
    //Handles retrieval of the JSON data from the API.
    func fetchDataAPI(completion: @escaping (Result<AdministrationResponseAPI, Error>) -> Void) {//The function provides a closure which is called when the API call is completed. The closure parameter  means that it will either be AdministrationResponseAPI instance or an Error instance. Implementation recommended in Pluralsight tutorial.
        
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
                let records = try decoder.decode(AdministrationResponseAPI.self, from: validData)//Data returned from API call gets parsed to an AdministrationResponseAPI instance.
                completion(.success(records))//Completion closure called if the API call is succesful.
            } catch let serializationError {
                completion(.failure(serializationError))//Completion closure called if the API call results in an error.
            }
        }
        task.resume()
    }
}

