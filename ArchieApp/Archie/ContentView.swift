//
//  ContentView.swift
//  a
//
//  Created by Will Rojas on 11/10/22.
//


import SwiftUI
import CoreLocation
import Foundation
import Combine
import UIKit

//let container = UILayoutGuide()

var options = ["McDonalds","Wendys","fresh&co","Chipotle","Dig","Shake Shack","Pelicana Chicken"]
var out = ""
var m = DeviceLocationService()
let callLock = NSCondition()
var callComplete = false
var bname = "Go"
var g: [String] = ["","",""]

//let g = reviewRank(adjectives: reviewTag(reviews: reviewList))

struct Restaurant: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }
    var name: String
    var id: String
}

var restaurants = [Restaurant]()

struct YelpAPI {
    let apikey = "80aSnHnyHk_OeP8nV1soG9yi6vkMnprpZLNQ75M-wpAKqYgiwgpEXmSToC7MV7d9Wo_PD8pbYMHQ_tLR5lG0qejq8MTZwenFxGWQso6gaHOg3d4xE4gZaKJaCTZXY3Yx"
    var domainURLString = "https://api.yelp.com/v3/businesses/search?location=Greenwich_Village&categories=restaurants&open_now=true"
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    mutating func setTerm(t: String, lat: String, lon: String) -> Void {
        if t != "" {
            let underscored_str = t.replacingOccurrences(of: " ", with: "_")
            domainURLString = "https://api.yelp.com/v3/businesses/search?latitude=\(lat)&longitude=\(lon)&radius=8000&categories=restaurants&open_now=true&term=\(underscored_str)"
        } else {
            domainURLString = "https://api.yelp.com/v3/businesses/search?latitude=\(lat)&longitude=\(lon)&radius=8000&categories=restaurants&open_now=true"
        }
        self.getRest() // get new set of restaurants based on term
    }
    
    fileprivate func getRest() -> Void {
        let url = URL(string: domainURLString)
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(apikey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                let _ = print("DataTask error: " + error.localizedDescription + "\n")
            }
            restaurants.removeAll() // clear restaurants from previous query
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]

                let _ = print(">>>>", json, #line,"<<<<")

                if let names = json["businesses"] as? [NSDictionary] {
                    for r in names {
                        let ro = Restaurant(name: r["name"] as! String, id: r["id"] as! String)
                            restaurants.append(ro)
                    }
                }
            } catch {
                let _ = print("caught")
            }
            callComplete = true
            callLock.broadcast() //wake up waiting threads
        }.resume()
    }
}

var api = YelpAPI()

/*
var loc = m.retLoc()
let lo = loc.location
let lon = lo?.coordinate.longitude
let lat = lo?.coordinate.latitude
 */

struct ContentView: View {
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    
    @State private var t = ""
    @State private var go = false
    let m = api.getRest()
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .top) {
                    Text("Let Archie Decide")
                        .padding().frame(width: 300, height: 100, alignment: .center).font(.custom("SignPainter",size: 34)).foregroundColor(.red)
                }
                ZStack(alignment: .center) {
                    Text("Any preferences?").foregroundColor(.black).frame(width: 200, height: 25, alignment: .trailing).font(.custom("Arial",size: 15))
                }
                ZStack(alignment: .center) {
                    TextField("", text: $t).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 25, alignment: .center).foregroundColor(.black)
                }.frame(width: 100, height: 25, alignment: .center).padding(.bottom, 50)
                
                ZStack(alignment: .center) {
                    Button(bname) {
                        go.toggle()
                        
                        
                        if(!go) {
                            //go = true
                            bname = "Go"
                            go.toggle()
                        }
                        
                        else {
                            bname = "Back"
                            bname = "Go"
                        }
                         
                        /*
                        if(!go) {
                            bname = "Go"
                            //go.toggle()
                            go = false
                            go.toggle()
                            go = true
                        }
                        else {
                            bname = "Go"
                            //go.toggle()
                            //go.toggle()
                            go = false
                            go.toggle()
                            //go = true
                        }
                            */
                            callComplete = false
                            
                            api.setTerm(t: t,lat: String(coordinates.lat),lon: String(coordinates.lon));
                            
                            while(!callComplete) {
                                callLock.wait() //wait until call completes
                            }
                            
                            if restaurants.count == 0 {
                                out = "No results"
                            } else {
                                let rs = restaurants.randomElement()!
                                //g = retRev(id: rs.id) as! [String]
                                //out = rs.name+"\n\(g)"
                                out = rs.name
                                print("OUT")
                                print(out)
                                print("ID")
                                print(rs.id)
                            }
                        }.frame(width: 50, height: 50, alignment: .center).padding().background(Color(red:0.8, green: 0, blue: 0)).clipShape(Circle()).foregroundColor(.white)
                }
                ZStack(alignment: .bottom) {
                        if go {
                            //let _ = reviewRank(adjectives: g)
                            Text(out).frame(width: 200, height: 300, alignment: .top).foregroundColor(.black)
                            Text("Latitude: \(coordinates.lat)")
                                .font(.largeTitle).frame(width: 200, height: 200, alignment: .top).foregroundColor(.black)
                            Text("Longitude: \(coordinates.lon)")
                                .font(.largeTitle).frame(width: 200, height: 100, alignment: .top).foregroundColor(.black)
                        }
                        }.onAppear {
                            observeCoordinateUpdates()
                            observeDeniedLocationAccess()
                            deviceLocationService.requestLocationUpdates()
                        
                        }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }.background(Image("vivid-blurred-colorful-wallpaper-background").resizable())
        }
    }
    
    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { coordinates in
                self.coordinates = (coordinates.latitude, coordinates.longitude)
            }
            .store(in: &tokens)
    }

    func observeDeniedLocationAccess() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Handle access denied event, possibly with an alert.")
            }
            .store(in: &tokens)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


