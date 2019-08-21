//
//  TimeCardView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 8/21/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import EPSignature


class TimeCardView: UIViewController {
    @IBOutlet var employeeLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var dateStepper: UIStepper!
    @IBOutlet var timeCardTable: UITableView!
    @IBOutlet var signatureImg: UIImageView!
    @IBOutlet var signatureBtn: UIButton!
    @IBOutlet var confirmBtn: UIButton!
    
    public static var employeeInfo: UserData.UserInfo?
    var date = Date()
    let dateFormatter = DateFormatter()
    let signature =
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeCardTable.delegate = self
        timeCardTable.dataSource = self
        
        dateFormatter.dateFormat = "MM-dd-yy"
        dateLabel.text = dateFormatter.string(from: date)
        
        dateStepper.value = Double(date.timeIntervalSince1970)
        
        if let info = TimeCardView.employeeInfo {
            employeeLabel.text = info.username
        }
    }
    
    @IBAction func goBack(_ sender: Any) { dismiss(animated: true, completion: nil) }
    @IBAction func showSIgnature(_ sender: Any) { self.presentSignature(vc: self, subTitle: "Please sign here", title: "Sign") }
    
    @IBAction func didChangeDate(_ sender: Any) {
        
    }
    
    func getTSdata() {
        guard let info = TimeCardView.employeeInfo else { return }
        APICalls().getTimesheet(username: info.username, date: date)
        
    }
    
}

extension TimeCardView: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "dayOweek") as? TimeCardCell else {
            return UITableViewCell()
        }
        // add timesheet data here
        
        return cell
    }
}

extension TimeCardView: EPSignatureDelegate {
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        signatureImg.image = signatureImage
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
    }
}

class TimeCardCell: UITableViewCell {
    
}
