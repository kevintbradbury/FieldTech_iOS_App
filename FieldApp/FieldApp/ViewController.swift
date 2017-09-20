//
//  ViewController.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class ViewController: UIViewController {

    var jobs: [Job.UserJob] = []
    let main = OperationQueue.main
    var location = UserData.init().userLocation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getJobs()
        UserLocation.instance.initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        UserLocation.instance.requestLocation(){ coordinate in
            
            self.location = coordinate
            
            if (self.location?.latitude)! > CLLocationDegrees(0.0) {
                print(self.location)
            } else {
                print("location failed")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getJobs() {
        
        APITestCall().fetchJobInfo() { jobs in
            self.jobs = jobs
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            print("Index 0 of JSON Jobs data \(self.jobs[0])")
        }
    }

}

