//
//  ToolSignOffView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 10/3/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import EPSignature

class ToolSignOffView: UIViewController, EPSignatureDelegate {
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var backBtn: UIButton!
    
    @IBOutlet var returnerSignatureView: UIView!
    @IBOutlet var printNameRenterField: UITextField!
    @IBOutlet var receiverSignatureView: UIView!
    @IBOutlet var printNameReceiverField: UITextField!
    @IBOutlet var sendButton: UIButton!

    let signOne = EPSignatureViewController(signatureDelegate: self, showsDate: true)
    let signTwo = EPSignatureViewController(signatureDelegate: self, showsDate: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSignatureViews()
        
//        let signatureVC = EPSignatureViewController(signatureDelegate: self, showsDate: true)
//        signatureVC.subtitleText = "Subtitle Text Here"
//        signatureVC.title = "Title Goes here"
//        let nav = UINavigationController(rootViewController: signatureVC)
//        present(nav, animated: true, completion: nil)
        
    }
    
    func setSignatureViews() {
        signOne
        signTwo
    }
    
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
        
    }
}
