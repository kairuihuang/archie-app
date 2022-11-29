//
//  ViewController.swift
//  Archie
//
//  Created by Will Rojas on 11/22/22.
//
/*
import Foundation
import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        /*
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
         */
        
        lazy var locationManager: CLLocationManager = {
            
            let manager = CLLocationManager()
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.delegate = self
            return manager
            
        }()
    }
    
}
 */
