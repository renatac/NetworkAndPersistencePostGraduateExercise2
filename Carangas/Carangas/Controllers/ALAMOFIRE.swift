//
//  ALAMOFIRE.swift
//  Carangas
//
//  Created by RENATA Frari on 5/14/21.
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

class ALAMOFIRE {
    
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
    
    private class func errorHandler(error: CarError) {
        var response: String = ""
        
        switch error {
        case .invalidJSON:
            response = "invalidJSON"
        case .noData:
            response = "noData"
        case .noResponse:
            response = "noResponse"
        case .url:
            response = "JSON inválido"
        case .taskError(let error):
            response = "\(error.localizedDescription)"
        case .responseStatusCode(let code):
            if code != 200 {
                response = "Algum problema com o servidor. :( \nError:\(code)"
            }
        }
        
        print(response)
        
    }
    
    class func delete(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .delete, onComplete: onComplete)   { (error) in
            errorHandler(error: error)
        }
    }
    
    class func update(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .update, onComplete: onComplete) { (error) in
            errorHandler(error: error)
        }
    }
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void ) {
        applyOperation(car: car, operation: .save, onComplete: onComplete) { (error) in
            errorHandler(error: error)
        }
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
        
        guard let url = URL(string: ALAMOFIRE.basePath) else {
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
        } //fim do loadCars
        
    }
    
    private class func applyOperation(car: Car, operation: RESTOperation , onComplete: @escaping (Bool) -> Void, onError: @escaping (CarError) -> Void ) {
        
        // o endpoint do servidor para update é: URL/id
        var urlString = basePath + "/" + (car._id ?? "")
        
        var httpMethod: HTTPMethod? = nil
        
        switch operation {
        case .delete:
            httpMethod = .delete
        case .save:
            httpMethod = .post
        case .update:
            httpMethod = .put
        }
        
        guard let url = URL(string: urlString) else {
            onComplete(false)
            return
        }
        
        guard (try? JSONEncoder().encode(car)) != nil else {
            onComplete(false)
            return
        }
        
        AF.request(url, method: httpMethod!, parameters: car, encoder: JSONParameterEncoder.default).response { response in
            
            if response.error != nil {
                onComplete(false)
            } else {
                switch response.result {
                case .success( _):
                    if response.response?.statusCode == 200 {
                        onComplete(true) // SUCESSO
                    }
                    onComplete(false)
                case .failure( _):
                    onComplete(false)
                }
            }
            
        }
    }
}
