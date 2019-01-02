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

class StoresMapView: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingBkgd: UIView!
    
    let main = OperationQueue.main
    public var todaysJob: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        
        UserLocation.instance.initialize()

        intitMap()
        findHWStores()
    }
    
    @IBAction func returnHome(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func intitMap() {
//        showLoading()
        
        guard let currentLoc = UserLocation.instance.currentCoordinate else { return }
        let span = MKCoordinateSpan(
            latitudeDelta: CLLocationDegrees(0.25), longitudeDelta: CLLocationDegrees(0.25)
        )
        let reg = MKCoordinateRegion(center: currentLoc, span:  span)
        
        mapView.setRegion(reg, animated: true)
        mapView.setCenter(currentLoc, animated: true)
        mapView.showsUserLocation = true
        mapView.delegate = self
    }
    
    func findHWStores() {
        showLoading()

        if let annotations: [MKAnnotation] = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        let req = MKLocalSearchRequest()
        req.naturalLanguageQuery = "hardware stores"
        req.region = mapView.region
        let search = MKLocalSearch.init(request: req)
        
        search.start { (res, error) in
            if error != nil {
                self.showAlert(withTitle: "Error", message: "Failed completing map search request.")
                self.stopLoading()
                
            } else {
                print("request was good")
                guard let searchResults = res?.mapItems else { return }
                
                for mapItem in searchResults {
                    guard let resultString: String = mapItem.name else { return }
                    
                    self.checkResults(resultString: resultString) { result in
                                let annotation = CustomAnnotation(
                                    title: mapItem.name!, coordinate: mapItem.placemark.coordinate, info: "customAnt"
                                )
                                self.mapView.addAnnotation(annotation)
                    }
                }
                self.stopLoading()
            }
        }
    }
    
    func checkResults(resultString: String, cb: (String) -> ()) {
        var result = ""
        
        if resultString == "Lowe's" { cb(resultString) }
        
        for char in resultString {
            if char == " " {
                
                if result == "The" { continue }
                else {
                    for store in FieldActions.SuppliesRequest().hardwareLocations {
                        if result == store { cb(result) }
                        else { continue }
                    }
                }
            } else { result += String(char) }
        }
    }
    
    func showLoading() {
        main.addOperation {
            self.activityIndicator.startAnimating()
            self.loadingBkgd.isHidden = false
        }
    }
    
    func stopLoading() {
        main.addOperation {
            self.activityIndicator.stopAnimating()
            self.loadingBkgd.isHidden = true
        }
    }
    
}

extension StoresMapView: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "customAnt"
        
        if annotation is CustomAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                let btn = UIButton(type: .detailDisclosure)
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                annotationView!.rightCalloutAccessoryView = btn
            } else {
                annotationView!.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
        guard let destination = annotation.title as? String else { return }
        
        ScheduleView.openMapsWithDirections(to: annotation.coordinate, destination: destination)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        findHWStores()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier ==  "suppliesReq" {
            let vc = segue.destination as! ChangeOrdersView
    
            vc.formTypeVal = "Supplies Request"
            vc.todaysJob = todaysJob
        }
    }
}

class CustomAnnotation: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
    
    init(title: String, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.coordinate = coordinate
        self.info = info
    }
}

