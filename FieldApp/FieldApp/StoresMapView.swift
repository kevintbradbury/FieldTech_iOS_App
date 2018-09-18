//
//  StoresMapView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 9/17/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class StoresMapView: UIViewController,  MKMapViewDelegate{

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var backButton: UIButton!
    
    var mapDelegate: MKMapViewDelegate?
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapDelegate = self
        UserLocation.instance.initialize()

        intitMap()
        findHWStores()
    }
    
    @IBAction func returnHome(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func intitMap() {
        guard let currentLoc = UserLocation.instance.currentCoordinate else { return }
        guard let region = UserLocation.instance.currentRegion else { return }
        
        mapView.setRegion(region, animated: true)
        mapView.setCenter(currentLoc, animated: true)
        mapView.showsUserLocation = true
    }
    
    func findHWStores() {
        let req = MKLocalSearchRequest()
        req.naturalLanguageQuery = "hardware store"
        req.region = mapView.region
        
        let search = MKLocalSearch.init(request: req)
        
        search.start { (res, error) in
            if error != nil {
                self.showAlert(withTitle: "Error", message: "Failed completing map search request.")
            } else {
                print("request was good")
                guard let allMapItems = res?.mapItems else { return }
                
                for mapItem in allMapItems {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = mapItem.placemark.coordinate
                    annotation.title = mapItem.name
                    
                    self.mapView.addAnnotation(annotation)
                }
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotn = annotation as? MKAnnotation else {
            showAlert(withTitle: "error", message: "couldnt cast annotation"); return nil
        }
        let identifier = "identifier"
        
        var annotationView = MKPinAnnotationView(annotation: annotn, reuseIdentifier: identifier)
        annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotn) as! MKPinAnnotationView
        annotationView.canShowCallout = true
        annotationView.calloutOffset = CGPoint(x: -5, y: -5)
        annotationView.leftCalloutAccessoryView = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        //            (frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
        guard let destination = annotation.title as? String else { return }
        
        ScheduleView.openMapsWithDirections(to: annotation.coordinate, destination: destination)
    }
    
}
