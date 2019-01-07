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
        req.naturalLanguageQuery = "hardware, tools"// "hardware stores"
        req.region = mapView.region
        let search = MKLocalSearch.init(request: req)
        
        search.start { (response, error) in
            if error != nil {
                self.showAlert(withTitle: "Error", message: "Failed completing map search request.")
                self.stopLoading()
                
            } else if let searchResults = response?.mapItems {
                self.setMapAnnotations(searchResults: searchResults)
            }
        }
    }
    
    func checkResults(resultString: String, cb: (String) -> ()) {
        var result = ""
        
        if resultString == "Lowe's" { cb(resultString) }
        
        for char in resultString {
            if char == " " {
                
                if result == "The " { continue }
                else {
                    for store in FieldActions.SuppliesRequest().hardwareLocations {
                        if result == store { cb(result) }
                        else { continue }
                    }
                }
            } else { result += String(char) }
        }
    }
    
    func setMapAnnotations(searchResults: [MKMapItem]) {
        var custmAnntns = [MKAnnotation]()
        
        for mapItem in searchResults {
            guard let title: String = mapItem.name,
                let phone: String = mapItem.phoneNumber else { continue }
            let latLon: CLLocationCoordinate2D = mapItem.placemark.coordinate
            let annotation = CustomAnnotation(title: title, subtitle: phone, coordinate: latLon, info: "customAnt")
            
            self.checkResults(resultString: title) { result in
                custmAnntns.append(annotation)
            }
        }
        
        if custmAnntns.count == 0 {
            
            for mapItem in searchResults {
                guard let title: String = mapItem.name,
                let phone: String = mapItem.phoneNumber else { continue }
                let latLon: CLLocationCoordinate2D = mapItem.placemark.coordinate
                let annotation = CustomAnnotation(title: title, subtitle: phone, coordinate: latLon, info: "customAnt")
                
                self.mapView.addAnnotation(annotation)
            }
        } else {
            self.mapView.addAnnotations(custmAnntns)
        }
        
        self.stopLoading()
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
    
    func makePhoneCall(phoneStr: String) {
        var phoneNumber = ""
        
        for char in phoneStr {
            if char == "(" || char == ")" || char == "-" || char == " " { continue }
            else { phoneNumber += "\(char)" }
        }
        let phone = phoneNumber.replacingOccurrences(of: "+1", with: "")
        let int = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if let url = URL(string: "tel://\(int)"), UIApplication.shared.canOpenURL(url) {
            
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        } else {
            print("Couldnt open phone number |\(int)|")
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
        guard let annotation = view.annotation,
            let destination = annotation.title as? String,
            let phoneStr = annotation.subtitle as? String else { return }
        
        let alert = UIAlertController(title: "Select", message: " Driving directions or \n Call \(destination)?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .destructive)
        let call = UIAlertAction(title: "Call", style: .default) { action in
            self.makePhoneCall(phoneStr: phoneStr)
        }
        let drive = UIAlertAction(title: "Driving Directions", style: .default) { action in
            ScheduleView.openMapsWithDirections(to: annotation.coordinate, destination: destination)
        }
        
        alert.addAction(drive)
        alert.addAction(call)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
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
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.info = info
    }
}

