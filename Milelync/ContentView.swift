//
//  ContentView.swift
//  Milelync
//
//  Created by Tim Chiang on 2022/8/21.
//
import SwiftUI
import Foundation
import Combine


struct ContentView: View {
    
    let detector: CurrentValueSubject<CGFloat, Never>
        let publisher: AnyPublisher<CGFloat, Never>
        init() {
            let detector = CurrentValueSubject<CGFloat, Never>(0)
            self.publisher = detector
                .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
                .dropFirst()
                .eraseToAnyPublisher()
            self.detector = detector
        }
    
    @EnvironmentObject var network: Network
    @State private var navigationIsShowing = false
    var body: some View {
        if network.statusCode != 200 {
            LoginView(network: network)
        }else{
            NavigationView{
                VStack{
                    Text("All Tickets")
                        .font(.title)
                        .bold()
                    
                    Button(action: {print("Hello World tapped!")}) {
                             Text("Unsolved: \(network.ticketList.unsolved)")
                                .padding(5)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(40)
                    }
                    .padding(1)
                    ScrollView (showsIndicators: false){
                        VStack(alignment: .leading) {
                            ForEach(network.ticketList.ticket_list) { tickets in
                                NavigationLink(destination:InsideTicket(tickets:tickets) ) {
                                    HStack(alignment:.top) {
                                        VStack(alignment: .leading){
                                            Text(String(tickets.id))
                                                .font(.system(size: 15))
                                            StatusSub(tickets:tickets)
                                        }
                                        VStack(alignment: .leading) {
                                            Text(tickets.subject)
                                                .font(.system(size: 15))
                                                .frame(width: 200, height:30,alignment: .topLeading)
                                            Text(tickets.customer_company.name)
                                                .font(.system(size: 10))
                                                .frame(alignment:.leading)
                                        }
                                        VStack(alignment:.leading){
                                            PrioritySub(tickets:tickets)
                                            TimeSub(tickets:tickets)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .frame(alignment: .leading)
                                    .padding()
                                  }.buttonStyle(PlainButtonStyle())
                            }
                            .frame(maxWidth:.infinity)
                            .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                            .onPreferenceChange(ViewOffsetKey.self) { detector.send($0) }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                            .onReceive(publisher) {
                                
                                print("Stopped on: \($0)")
                            }
                    .padding(.vertical)
                    .onAppear {
                        network.getTickets()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                
        }
    }
    
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct InsideTicket: View {
    @EnvironmentObject var network: Network
    let tickets: TicketList.Tickets
    var body: some View {
        ScrollView (showsIndicators: false){
            Text(tickets.subject)
                .font(.title)
                .bold()
            Text(String(network.ticketModel.id))
                .font(.headline)
            VStack(alignment: .leading){
                TicketTimeSub(ticket: network.ticketModel)
                Spacer()
//                Text("Service: "+network.ticketModel.service)
                Text("Customer: customer")
//                Text("Project ID: "+network.ticketModel.cloud_service_uid)
                Text("Author: Authoer")
                Text("Sales: sales")
                Text("Description:").padding().font(.headline)
                Spacer()
                Text(Description)
                    .padding()
            }
            .contentShape(Rectangle())
            .frame(alignment: .leading)
            .padding()
            VStack(alignment: .leading){
                Text("Comments: ").padding().font(.headline)
                Spacer()
                ForEach(network.ticketResponse){
                    response in
                    ResponseSub(response: response)
                }
            }.contentShape(Rectangle())
                .frame(alignment: .leading)
                .padding()
        }
        .gesture(
           DragGesture().onChanged { value in
              print(value)
           }
        )
        .padding(.vertical)
        .onAppear {
            network.getTicket(displayName: tickets.display_name)
            network.getTicketResponse(displayName: tickets.display_name)
        }
        
    }
  
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Network())
.previewInterfaceOrientation(.portrait)
    }
}

struct LoginView: View{
    var network: Network
    @State var email: String = ""
    @State var password: String = ""
    let savedEmail = UserDefaults.standard.string(forKey: "email")
    let savedPassword = UserDefaults.standard.string(forKey: "password")

    var body: some View{
        VStack{
            Text("MileLync Image").padding()
            Text("Sign in to your account").padding()
            VStack(alignment: .leading, spacing: 16){
                Text("Email")
                    .font(.callout).bold()
                TextField("Enter your email",text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                Text("Password")
                    .font(.callout).bold()
                SecureField("Enter passowrd",text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)

                Button("Login"){
                    UserDefaults.standard.set(self.email, forKey: "email")
                    UserDefaults.standard.set(self.password, forKey: "password")
                    network.loginMileLync(email: email, password: password)
                }
                .padding()
                .background(Color(UIColor.systemBlue))
                .cornerRadius(10)
                .foregroundColor(Color.white)
                
            } .padding(.all, 36)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
//            Text(savedEmail ??  "")
//            Text(savedPassword ?? "")
        }.onAppear{
            network.getTickets()
        }
    }
}
struct StatusSub: View {
    let tickets: TicketList.Tickets
    var body: some View {
        Group{
            if tickets.status.hasSuffix("New"){
                Text(tickets.status)
                    .frame(width:55,height:15,alignment:.center)
                    .font(.system(size: 8))
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                
            }else if tickets.status.hasSuffix("In Progress"){
                Text(tickets.status)
                    .frame(width:55,height:15,alignment:.center)
                    .font(.system(size: 8))
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else if tickets.status.hasSuffix("Closed"){
                Text(tickets.status)
                    .frame(width:55,height:15,alignment:.center)
                    .font(.system(size: 8))
                    .background(.gray)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else{
                Text(tickets.status)
                    .frame(width:55,height:15,alignment:.center)
                    .font(.system(size: 8))
                    .background(.red)ㄋㄚ
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
    }
}
struct PrioritySub: View {
    let tickets: TicketList.Tickets
    
    var body: some View {
        let priority = tickets.priority ?? ""
        Group{
            if priority.hasSuffix("p4"){
                Text(priority)
                    .font(.system(size: 10))
                    .frame(width:25,height:20,alignment:.center)
                    .background(.yellow)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else if priority.hasSuffix("p3"){
                Text(priority)
                    .font(.system(size: 10))
                    .frame(width:25,height:20,alignment:.center)
                    .background(Color(hue: 0.061, saturation: 0.588, brightness: 0.991))
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else if priority.hasSuffix("p2"){
                Text(priority)
                    .font(.system(size: 10))
                    .frame(width:25,height:20,alignment:.center)
                    .background(Color(hue: 0.06, saturation: 0.741, brightness: 0.886))
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else if priority.hasSuffix("p1"){
                Text(priority)
                    .font(.system(size: 10))
                    .frame(width:25,height:15,alignment:.center)
                    .background(.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }else{
                Text("--")
                    .font(.system(size: 10))
                    .frame(width:25,height:15,alignment:.center)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
    }
}
struct TimeSub: View {
    let tickets: TicketList.Tickets
    var body: some View {
        timeCal(updateString:tickets.updated_at)
    }
}
private func timeCal(updateString: String) -> Text{
    //"2022-05-01T00:00:07"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    
    let now = Date.now
    let currneDate = dateFormatter.string(from: now)
    
    let xmas = dateFormatter.date(from: updateString)
    let newYear = dateFormatter.date(from: currneDate)
    
    let diffSeconds = newYear!.timeIntervalSinceReferenceDate - xmas!.timeIntervalSinceReferenceDate
    let currnetTime = stringFromTimeInterval(interval: String(diffSeconds))
    return Text(String(currnetTime))
        .font(.system(size: 10))
    
           

}
private func stringFromTimeInterval (interval: String) -> String {
        let endingDate = Date()
        if let timeInterval = TimeInterval(interval) {
            let startingDate = endingDate.addingTimeInterval(-timeInterval)
            let calendar = Calendar.current

            let componentsNow = calendar.dateComponents([.hour, .minute, .second], from: startingDate, to: endingDate)
            if let hour = componentsNow.hour, let minute = componentsNow.minute, let seconds = componentsNow.second {
                
                if hour > 24{
                    let day = hour / 24
                    return "\(day) Days Ago"
                }else if hour > 0{
                    return "\(hour) Hours Ago"
                }else if hour < 0{
                    return "\(minute) Minute Ago"
                }else if hour == 0 && minute == 0{
                    return "a few second age"
                }else {
                    return "\(hour):\(minute):\(seconds)"
                }
            } else {
                return "00:00:00"
            }

        } else {
            return "00:00:00"
        }
    }
struct TicketTimeSub: View {
    let ticket: TicketModel
    var body: some View {
        HStack(alignment:.top){
            Text("Create time:" )
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text("Last update time:" )
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}
struct ResponseSub: View {
    let response: TicketResponse
    var body: some View {
        Group{
            // CloudMile Support
            if response.created_by_operator{
                VStack(alignment: .leading){
                    HStack(){
                        Text("Creator").font(.headline)
                        Text("Create at")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Spacer()
                    Text("Description")
                }
                .frame(maxWidth: .infinity, alignment:.leading)
                .padding()
                .background(Color(#colorLiteral(red: 0.6667672396, green: 0.7527905703, blue: 1, alpha: 0.2662717301)))
            }else{
                // Customer
                VStack(alignment: .leading){
                    HStack(){
                        Text("Creator").font(.headline)
                        Text("Create at")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Spacer()
                    Text("Description")
                }
                .frame(maxWidth: .infinity, alignment:.leading)
                .padding()
                .background(Color.gray)
            }
            
        }
    }
}
