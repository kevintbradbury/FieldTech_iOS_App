//
//  APITestCall.swift
//  FieldApp
//
//  Created by Kevin Bradbury on 9/19/17.
//  Copyright © 2017 Kevin Bradbury. All rights reserved.
//

import Foundation


class APITestCall {
    
    let jsonString = "https://s3-us-west-1.amazonaws.com/databasejsontest/Jobs+Sample.json"
    
    func fetchJobInfo(callback: @escaping ([Job.UserJob]) -> ()) {
        
        let url = URL(string: jsonString)!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {data, response, error in
            
            if error != nil {
                
                print("failed to fetch JSON from AWS")
                return
            }
            guard let verifiedData = data else {
                
                print("could not verify data from dataTask")
                return
            }
            let jobs: [Job.UserJob] = self.parseJobs(from: verifiedData)
            
            callback(jobs)
        }
        
        task.resume()
    }
    
    func parseJobs(from data: Data) -> [Job.UserJob] {
        
        var jobsArray: [Job.UserJob] = []
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonArray = json as? NSArray else {
                
                return jobsArray
        }
     
        for index in jsonArray {
            
//            guard let object = index as? NSDictionary else { continue }
            
            guard let job = Job.UserJob.jsonToDictionary(dictionary: index as! NSDictionary) else { continue }
            jobsArray.append(job)
        }

        return jobsArray
    }
    
}
