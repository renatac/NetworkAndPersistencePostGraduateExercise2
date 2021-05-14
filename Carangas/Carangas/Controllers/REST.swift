//
//  REST.swift
//  Carangas
//
//  Created by Douglas Frari on 5/10/21.
//  Copyright © 2021 Eric Brito. All rights reserved.
//


import Alamofire
import Foundation

enum CarError {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}

enum RESTOperation {
    case save
    case update
    case delete
}

class REST {
    
    // URL + endpoint
    private static let basePath = "https://carangas.herokuapp.com/cars"
    
    // URL TABELA FIPE
    private static let urlFipe = "https://fipeapi.appspot.com/api/1/carros/marcas.json"
    
    // session criada automaticamente e disponivel para reusar
    private static let session = URLSession(configuration: configuration)
    
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Content-Type":"application/json"]
        config.timeoutIntervalForRequest = 10.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    
    class func delete(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .delete, onComplete: onComplete)
    }
    
    class func update(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .update, onComplete: onComplete)
    }
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .save, onComplete: onComplete)
    }
    
    // o metodo pode retornar um array de nil se tiver algum erro
    class func loadBrands(onComplete: @escaping ([Brand]?) -> Void, onError: @escaping (CarError) -> Void) {
        
        guard let url = URL(string: urlFipe) else {
            onError(.url)
            return
        }
        
        AF.request(url).responseJSON {  response in
            
         if response.error != nil {
                print(response.error.debugDescription)
                onError(.taskError(error: response.error!))
            } else {
               switch response.result {
               case .success( _):
                    // servidor respondeu com sucesso :)
                    guard let data = response.data else {
                        // ERROR porque o data é invalido
                        onError(.noData)
                        return
                    }
                    do {
                        let brands = try JSONDecoder().decode([Brand].self, from: data)
                        onComplete(brands) // SUCESSO
                    }
                    catch {
                        print(error.localizedDescription)
                        onError(.invalidJSON)
                    }
                case .failure(let error):
                    print(error)
                    print("Algum status inválido(-> \(response.result) <-) pelo servidor!! ")
                    onError(.responseStatusCode(code: 500))
                }
            }
            
        }
    }// fim do loadBrands
    
    
    class func loadCars(onComplete: @escaping ([Car]) -> Void, onError: @escaping (CarError) -> Void) {
        
        guard let url = URL(string: REST.basePath) else {
            onError(.url)
            return
        }
        
        AF.request(url).responseJSON {  response in
            
         if response.error != nil {
                print(response.error.debugDescription)
                onError(.taskError(error: response.error!))
            } else {
               switch response.result {
               case .success( _):
                    // servidor respondeu com sucesso :)
                    guard let data = response.data else {
                        // ERROR porque o data é invalido
                        onError(.noData)
                        return
                    }
                    do {
                        let cars = try JSONDecoder().decode([Car].self, from: data)
                        onComplete(cars) // SUCESSO
                    }
                    catch {
                        print(error.localizedDescription)
                        onError(.invalidJSON)
                    }
                case .failure(let error):
                    print(error)
                    print("Algum status inválido(-> \(response.result) <-) pelo servidor!! ")
                    onError(.responseStatusCode(code: 500))
                }
            }
            
        }
    }

    
    private class func applyOperation(car: Car, operation: RESTOperation , onComplete: @escaping (Bool) -> Void ) {
        
        // o endpoint do servidor para update é: URL/id
        let urlString = basePath + "/" + (car._id ?? "")
        
        guard let url = URL(string: urlString) else {
            onComplete(false)
            return
        }
        var request = URLRequest(url: url)
        var httpMethod: String = ""
        
        switch operation {
        case .delete:
            httpMethod = "DELETE"
        case .save:
            httpMethod = "POST"
        case .update:
            httpMethod = "PUT"
        }
        request.httpMethod = httpMethod
        
        // transformar objeto para um JSON, processo contrario do decoder -> Encoder
        guard let json = try? JSONEncoder().encode(car) else {
            onComplete(false)
            return
        }
        request.httpBody = json
        
        session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                // verificar e desembrulhar em uma unica vez
                guard let response = response as? HTTPURLResponse, response.statusCode == 200, let _ = data else {
                    onComplete(false)
                    return
                }
                
                // ok
                onComplete(true)
                
            } else {
                onComplete(false)
            }
            
        }.resume()
        
    }
}
