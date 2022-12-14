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
import MapKit

//let container = UILayoutGuide()

var rating = "init"
var price = "init"
var options = ["McDonalds","Wendys","fresh&co","Chipotle","Dig","Shake Shack","Pelicana Chicken"]
var out = ""
//var m = DeviceLocationService()
let callLock = NSCondition()
var callComplete = false
let locCallLock = NSCondition()
var locCallComplete = false
let revCallLock = NSCondition()
var revCallComplete = false
var bname = "Go"
var crev: Any = ""
var g: Any = ""
var rurl = ""
var lat: Double = 0
var lon: Double = 0
var name: String = ""
var mRate: Double = 0
var maxPr = "$$$$"
var rad: Double = 1600
//var g: [String] = ["","",""]
//let vc = ViewController()

//let g = reviewRank(adjectives: reviewTag(reviews: reviewList))

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to: nil, from: nil, for: nil)
    }
}

//code by ccwasden on stackexchange
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) }
        else { self }
    }
}

struct Restaurant: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }
    var name: String
    var rating: String
    var price: String
    var id: String
    var url: String
    var lat: Double
    var lon: Double
}

var restaurants = [Restaurant]()

struct YelpAPI {
    let apikey = "80aSnHnyHk_OeP8nV1soG9yi6vkMnprpZLNQ75M-wpAKqYgiwgpEXmSToC7MV7d9Wo_PD8pbYMHQ_tLR5lG0qejq8MTZwenFxGWQso6gaHOg3d4xE4gZaKJaCTZXY3Yx"
    var domainURLString = "https://api.yelp.com/v3/businesses/search?location=Greenwich_Village&categories=restaurants&open_now=true"
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    mutating func setTerm(t: String, lat: String, lon: String, radius: Int) -> Void {
        print("INPLAT")
        print(lat)
        print("INPLON")
        print(lon)
        if t != "" {
            let underscored_str = t.replacingOccurrences(of: " ", with: "_")
            domainURLString = "https://api.yelp.com/v3/businesses/search?latitude=\(lat)&longitude=\(lon)&radius=\(radius)&categories=restaurants&open_now=true&term=\(underscored_str)"
        } else {
            domainURLString = "https://api.yelp.com/v3/businesses/search?latitude=\(lat)&longitude=\(lon)&radius=\(radius)&categories=restaurants&open_now=true"
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
                        let rt = r["rating"] as! NSNumber
                        rating = rt.stringValue
                        print("RATING TYPE")
                        /*
                        if let _ = rt as? String {
                            rating = rt as! String
                        }
                        else {
                            rating = ""
                            print(rt as! NSNumber)
                        }
                         */
                        print("RATE")
                        print(rating)
                        if let o = r["price"] as? String {
                            price = r["price"] as! String
                        }
                        else {
                            price = ""
                        }
                        print(r)
                        let ro = Restaurant(name: r["name"] as! String, rating: rating, price: price, id: r["id"] as! String, url: r["url"] as! String, lat: (r["coordinates"] as! NSDictionary)["latitude"] as! Double, lon: (r["coordinates"] as! NSDictionary)["longitude"] as! Double)
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


struct prefView: View {
    @State var refresh: Bool = false
    @Binding var showingSettings: Bool
    @State private var minRate = String(mRate)
    @State private var maxPrice = maxPr
    @State private var radius = String(Int(rad/1600))
    let prices = ["$","$$","$$$","$$$$"]
        //@Environment(\.dismiss) var dismiss
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                ZStack(alignment: .center) {
                    Text("Minimum Rating (0 to 5)").foregroundColor(.black).frame(width: 200, height: 25, alignment: .top).font(.custom("Arial",size: 15))
                }.frame(width: 200, height: 25, alignment: .top)
                ZStack(alignment: .center) {
                    TextField("", text: $minRate).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 5, alignment: .center).foregroundColor(.black)
                }.frame(width: 100, height: 5, alignment: .top)//.padding(50)
                    ZStack{}.frame(width: 200, height: 50, alignment: .center)
                ZStack(alignment: .center) {
                    Text("Maximum Price ($ to $$$$)").foregroundColor(.black).frame(width: 200, height: 25, alignment: .bottom).font(.custom("Arial",size: 15))
                }.frame(width: 200, height: 25, alignment: .bottom)//.padding()
                ZStack(alignment: .bottom) {
                            Picker("Max Price", selection: $maxPrice) {
                                ForEach(prices, id: \.self) {
                                    Text($0)
                                }
                            }//.frame(width: 100, height: 25, alignment: .center)
                    //Text("Hello")
                }.frame(width: 100, height: 20, alignment: .bottom)
                    ZStack{}.frame(width: 200, height: 15, alignment: .center)
                ZStack(alignment: .center) {
                    Text("Radius (in miles)").foregroundColor(.black).frame(width: 200, height: 25, alignment: .bottom).font(.custom("Arial",size: 15))
                }.frame(width: 100, height: 25, alignment: .center)//.padding()
                ZStack(alignment: .top) {
                    TextField("", text: $radius).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 25, alignment: .center).foregroundColor(.black)
                }.frame(width: 100, height: 25, alignment: .bottom)
                ZStack(alignment: .bottom) {
                    Button("Main Screen") {
                        refresh.toggle()
                        //let mr = minRate.wrappedValue
                        mRate = Double(minRate)!
                        maxPr = maxPrice
                        rad = Double(radius)!*1600
                        showingSettings = false
                    }.frame(width: 200, height: 50, alignment: .bottom)
                }
                }//.background(Color(uiColor: .white.withAlphaComponent(0.9)))
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center).background(Image("vivid-blurred-colorful-wallpaper-background").resizable())
        }
    }
}


struct ContentView: View {
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    
    @State var refresh: Bool = false
    @State private var t = ""
    @State private var go = false
    @State private var directions = false
    let m = api.getRest()
    @State private var showingSettings = false

    //@Binding var out: String
    
    var body: some View {
        let _ = observeCoordinateUpdates()
        let _ = observeDeniedLocationAccess()
        let _ = deviceLocationService.requestLocationUpdates()
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .top) {
                    Text("Let Archie Decide")
                        .padding().frame(width: 300, height: 100, alignment: .center).font(.custom("SignPainter",size: 34)).foregroundColor(.red)
                }/*.onAppear {
                    observeCoordinateUpdates()
                    observeDeniedLocationAccess()
                    deviceLocationService.requestLocationUpdates()
                }
                  */
                ZStack(alignment: .center) {
                    Text("Any preferences?").foregroundColor(.black).frame(width: 200, height: 25, alignment: .center).font(.custom("Arial",size: 15))
                }
                ZStack(alignment: .center) {
                    TextField("", text: $t).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 25, alignment: .center).foregroundColor(.black)
                }.frame(width: 100, height: 25, alignment: .center).padding(.bottom, 50)
                
                ZStack(alignment: .center) {
                    Button(bname) {
                        go.toggle()
                        
                        
                        if(!go) {
                            go = true
                            bname = "Go"
                        }
                        /*
                        else {
                            bname = "Back"
                        }
                         */
                        //vc.viewDidLoad()
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
                            
                            print("MYLAT")
                            print(coordinates.lat)
                            print("MYLON")
                            print(coordinates.lon)
                        api.setTerm(t: t,lat: String(coordinates.lat),lon: String(coordinates.lon), radius: Int(rad));
                            
                            while(!callComplete) {
                                callLock.wait() //wait until call completes
                            }
                        var prefRest = [Restaurant]()
                        var rs: Restaurant = Restaurant(name: "nil", rating: "nil", price: "$$$$$", id: "nil", url: "https://google.com", lat: 0, lon: 0)
                        
                            if restaurants.count == 0 {
                                out = "No results"
                                refresh.toggle()
                            }
                        
                        else if (maxPr != "$$$$") || (mRate > 0) {
                            prefRest.removeAll()
                            for r in restaurants {
                                if (r.price.count <= maxPr.count) && (Double(r.rating)! >= mRate) {
                                    prefRest.append(r)
                                }
                            }
                            if prefRest.count == 0 {
                                out = "No results"
                                refresh.toggle()
                            }
                            else {
                                rs = prefRest.randomElement()!
                                print("PREFERENCE")
                                print(rs)
                                lat = rs.lat
                                lon = rs.lon
                                name = rs.name
                                
                                
                                g = retRev(id: rs.id)
     
                                var nl = "init"
                                if (rs.price == "") {
                                    nl = ""
                                }
                                else {
                                    nl = "\n"
                                }
                                rurl = rs.url
                                if let a = g as? [String] {
                                    //let g = g as! NSArray
                                    out = rs.name+"\n\(rs.rating)"+nl+"\(rs.price)"

                                }
                                else {
                                    out = rs.name+"\n\(rs.rating)"+nl+"\(rs.price)"+"\n\(g)"
                                }
                                refresh.toggle()
                                print("PREFMYOUT")
                                print(out)
                            }
                        }
                            
                        
                            else {

                                rs = restaurants.randomElement()!
                                
                                print("CURRNAME")
                                print(rs.name)
                                print("ID")
                                print(rs.id)
                                
                                lat = rs.lat
                                lon = rs.lon
                                name = rs.name
                                
                                
                                //revCallComplete = false
                                g = retRev(id: rs.id)
                                /*
                                while(!revCallComplete) {
                                    revCallLock.wait() // wait until call completes
                                }
                                 */
                                print("CREV")
                                print(crev)
                                //let gc = g as! NSArray
                                /*
                                if (g.count == 0) {
                                    out = rs.name
                                }
                                else {
                                    out = rs.name+"\n\(g.firstObject)"
                                }
                                 */
                                
                                //only make newline if price available
                                var nl = "init"
                                if (rs.price == "") {
                                    nl = ""
                                }
                                else {
                                    nl = "\n"
                                }
                                rurl = rs.url
                                if let a = g as? [String] {
                                    //let g = g as! NSArray
                                    out = rs.name+"\n\(rs.rating)"+nl+"\(rs.price)"

                                }
                                else {
                                    out = rs.name+"\n\(rs.rating)"+nl+"\(rs.price)"+"\n\(g)"
                                }
                                 
                                //out = rs.name+"\n\(type(of:g))"
                                //out = rs.name
                                print("OUTP")
                                print(out)
                                print("ID")
                                print(rs.id)
                                refresh.toggle()
                            }
                        
                        }.frame(width: 50, height: 50, alignment: .center).padding().background(Color(red:0.8, green: 0, blue: 0)).clipShape(Circle()).foregroundColor(.white)/*.onAppear {
                            observeCoordinateUpdates()
                            observeDeniedLocationAccess()
                            deviceLocationService.requestLocationUpdates()
                        }
                                                                                                                                                                               */
                }/*.onAppear {
                    observeCoordinateUpdates()
                    observeDeniedLocationAccess()
                    deviceLocationService.requestLocationUpdates()
                }
                  */
                ZStack(alignment: .center) {}.frame(width: 50, height: 30, alignment: .center)
                ZStack(alignment: .top) {
                        if go {
                            let _ = print("MYOUT")
                            let _ = print(out)
                            //let _ = go.toggle()
                            //let _ = hideKeyboard()
                            //let _ = reviewRank(adjectives: g)
                            Text(out).frame(width: 200, height: 300, alignment: .top).foregroundColor(.black).multilineTextAlignment(.center)
                            Link("Yelp Page", destination: (URL(string: rurl) ?? URL(string: "google.com"))!).frame(width: 200, height: 300, alignment: .center).foregroundColor(.blue)
                            //VStack(alignment: .center) {}.frame(width: 100, height: 400, alignment: .center)
                            Button("Directions") {
                                directions.toggle()
                                let dir = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                                //mapView(MapView: mv, annotationView: av, calloutAccessoryControlTapped: uc)
                                openMapsAppWithDirections(to: dir, destination: name)
                            }.frame(width: 200, height: 200, alignment: .center).padding(100)
                            
                            if directions {
                                /*
                                let mv = MKMapView()
                                let av = MKAnnotationView()
                                let uc = UIControl()
                            struct mview: view: mapView(MapView: mv, annotationView: av, calloutAccessoryControlTapped: uc)
                                 */
                                //openMaps()
                            }
                            /*
                            Text("Latitude: \(coordinates.lat)")
                                .font(.largeTitle).frame(width: 200, height: 200, alignment: .center).foregroundColor(.black)
                            Text("Longitude: \(coordinates.lon)")
                                .font(.largeTitle).frame(width: 200, height: 100, alignment: .bottom).foregroundColor(.black)
                             */
                        }

                }.if(!go) {$0.padding(125)}/*.onAppear {
                    observeCoordinateUpdates()
                    observeDeniedLocationAccess()
                    deviceLocationService.requestLocationUpdates()
                }
                   */

                ZStack(alignment: .bottom) {
                    Button("Criteria") {
                        showingSettings = true
                    }.frame(width: geometry.size.width/2, height: 5, alignment: .bottom).if(go) {$0.padding(150)}
                    if showingSettings {
                    }
                }.frame(width: 200, height: 5, alignment: .bottom)
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top).background(Image("vivid-blurred-colorful-wallpaper-background").resizable()).sheet(isPresented: $showingSettings) {
                prefView(showingSettings: $showingSettings)
            }
        }.onAppear {
            //locCallComplete = false
            observeCoordinateUpdates()
            /*
            while(!locCallComplete) {
                locCallLock.wait()
            }
             */
            observeDeniedLocationAccess()
            //locCallComplete = false
            deviceLocationService.requestLocationUpdates()
            print("ONAPPEAR WORKS")
            print("TLAT")
            print(coordinates.lat)
            print("TLON")
            print(coordinates.lon)
        }
    }

    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Handle \(error) for error and finished subscription.")
                }
            } receiveValue: { coordinates in
                self.coordinates = (coordinates.latitude, coordinates.longitude)
            }
            .store(in: &tokens)
        /*
        locCallComplete = true
        locCallLock.broadcast() //wake sleeping threads
         */
    }


    func observeDeniedLocationAccess() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Handle access denied event, possibly with an alert.")
            }
            .store(in: &tokens)
    }

    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destination name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    func mapView(MapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped Control: UIControl) {

      if Control == annotationView.leftCalloutAccessoryView {
        if let annotation = annotationView.annotation {
          // Unwrap the double-optional annotation.title property or
          // name the destination "Unknown" if the annotation has no title
          let destinationName = (annotation.title ?? nil) ?? "Unknown"
            openMapsAppWithDirections(to: annotation.coordinate, destination: destinationName)
        }
      }

    }
        /*
        return Group {
            if showingSettings {
                prefView()
            }
            else {
                mainView()
            }
        }
         */

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


