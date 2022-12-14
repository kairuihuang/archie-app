//
//  ViewController.swift
//  Archie
//
//  Created by Will Rojas on 12/6/22.
//

import Foundation
import MapKit
import UIKit

class ViewController: UIViewController, MKMapViewDelegate {


@IBOutlet weak var mapview: MKMapView!

override func viewDidLoad() {
    super.viewDidLoad()

    mapview.delegate = self

    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.203314, longitude: -8.410257), addressDictionary: nil))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.112808, longitude: -8.498689), addressDictionary: nil))
    request.requestsAlternateRoutes = false
    request.transportType = .walking

    let directions = MKDirections(request: request)

    directions.calculate { [unowned self] response, error in
        guard let unwrappedResponse = response else { return }

        for route in unwrappedResponse.routes {
            self.mapview.addOverlay(route.polyline)
            self.mapview.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
}


func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = UIColor.blue
        polylineRenderer.fillColor = UIColor.red
        polylineRenderer.lineWidth = 2
        return polylineRenderer


    }

}

