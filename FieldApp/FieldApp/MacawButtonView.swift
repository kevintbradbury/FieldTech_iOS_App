//
//  MacawButtonView.swift
//  FieldApp
//
//  Created by MB Mac 3 on 10/6/18.
//  Copyright © 2018 Kevin Bradbury. All rights reserved.
//

import Foundation
import Macaw
import FanMenu

class AnimatedHomeButton: MacawView {
    
    let view = MacawView()
    
    required init?(coder aDecoder: NSCoder) {
        let node = Text(text: "Sample")
        
        super.init(node: node, coder: aDecoder)
    }
    
    func generateHomeBtn() {
        
    }
    
}
