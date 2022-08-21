//
//  Network.swift
//  Milelync
//
//  Created by Tim Chiang on 2022/8/21.
//

import SwiftUI

class Network: ObservableObject {
    @Published var ticketList : TicketList = TicketList()
    
    @Published var ticketModel = TicketModel()
    @Published var ticketResponse = [TicketResponse]()
    @Published var errorLog: String = ""
    @Published var data: String = ""
    @Published var accessToekn: String = ""
    @Published var statusCode: Int = 400
    
    
    func loginMileLync(email:String, password:String){
        guard let url = URL(string: "URL") else { fatalError("Missing URL") }
        var loginRequest = URLRequest(url: url)
        let encoder = JSONEncoder()
        let user = LoginUser(username: email, password: password)
        let data = try? encoder.encode(user)
        loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        loginRequest.httpBody = data
        loginRequest.httpMethod="POST"
        URLSession.shared.dataTask(with: loginRequest) { data, response, error in
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode == 200{
                self.statusCode = 200
                if let data = data {
                    do {
                        var decoder = JSONDecoder()
                        var createUserResponse = try decoder.decode(LoginResponse.self, from: data)
                        self.accessToekn = String(describing: "Bearer " + createUserResponse.success.access)
                        UserDefaults.standard.set(self.accessToekn, forKey: "access")

                    } catch  {
                        self.errorLog = "Login Error:" + error.localizedDescription
                    }
                }
            }
            
        }.resume()
    }
    
    func getTicketResponse(displayName:String){
        guard let url = URL(string: "URL"+displayName+"URL") else { fatalError("Missing URL") }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(UserDefaults.standard.string(forKey: "access"), forHTTPHeaderField: "Authorization")
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.errorLog = "Get Ticket Response:" + error.localizedDescription
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode == 200 {
                guard let data = data else { return }
                self.data = String(describing: data)
                DispatchQueue.main.async {
                    do {
                        let decodedUsers = try JSONDecoder().decode([TicketResponse].self, from: data)
                        self.ticketResponse = decodedUsers
                    } catch let error {
                        self.errorLog = "Ticket - JSON Decoder:" + String(describing: error)
                    }
                }
            }else{
                self.errorLog = "Status Code Response:" + String(describing: response.statusCode) + "Pls Refresh"
            }
        }
        dataTask.resume()
    }
    
    func getTicket(displayName:String){
        guard let url = URL(string: "URL"+displayName+"/") else { fatalError("Missing URL") }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(UserDefaults.standard.string(forKey: "access"), forHTTPHeaderField: "Authorization")
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.errorLog = "Get Ticket:" + error.localizedDescription
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode == 200 {
                self.statusCode = 200
                guard let data = data else { return }
                self.data = String(describing: data)
                DispatchQueue.main.async {
                    do {
                        let decodedUsers = try JSONDecoder().decode(TicketModel.self, from: data)
                        self.ticketModel = decodedUsers
                    } catch let error {
                        self.errorLog = "Ticket - JSON Decoder:" + String(describing: error)
                        print(self.errorLog)
                    }
                }
            }else{
                self.errorLog = "Status Code:" + String(describing: response.statusCode) + "Pls Refresh"
                
            }
        }
        dataTask.resume()
    }
    
    
    
    func getTickets(){
        guard let url = URL(string: "URL") else { fatalError("Missing URL") }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(UserDefaults.standard.string(forKey: "access"), forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod="GET"
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.errorLog = "GetTickets:" + error.localizedDescription
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode == 200 {
                self.statusCode = 200
                guard let data = data else { return }
//                self.data = String(describing: data)
                DispatchQueue.main.async {
                    do {
                        // Show as raw
                    
//                        print("JSON String: \(String(data: data, encoding: .utf8))")
                        let decoder = JSONDecoder()
                        let decodedUsers = try decoder.decode(TicketList.self, from: data)
                        self.ticketList = decodedUsers
                    } catch let error {
                        print("Tickets - JSON Decoder:\(String(describing: error))")
                        self.errorLog = "Tickets - JSON Decoder:" + String(describing: error)
                    }
                }
            }else{
                self.errorLog = "Status Code:" + String(describing: response.statusCode) + "Pls Refresh"
            }
        }
        dataTask.resume()
        
    }
    struct LoginUser: Encodable {
        let username: String
        let password: String
    }
    struct LoginResponse: Decodable {
        let success: success
        struct success:Decodable{
            let refresh :String
            let access : String
            let first_login : Bool
        }
    }
    
}
