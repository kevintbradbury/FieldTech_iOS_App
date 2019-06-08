//
//  CustomViews.swift
//  FieldApp
//
//  Created by MB Mac 3 on 4/5/19.
//  Copyright © 2019 Kevin Bradbury. All rights reserved.
//

import Foundation
import UIKit
import Macaw


public class HomeBkgd: MacawView {
    required init?(coder aDecoder: NSCoder) {
        let h = UIScreen.main.bounds.height,
        w = UIScreen.main.bounds.width,
        node = Group(),
        shp = Shape(
            form: Rect(x: 0.0, y: 0.0, w: Double(w), h: Double(h / 2)),
            fill: LinearGradient(degree: 90, from: Color.black, to: Color.white),
            stroke: Stroke(fill: Color.clear, width: 0.0)
        ),
        shpTwo = Shape(
            form: Rect(x: 0.0, y: Double(h / 2), w: Double(w), h: Double(h / 2)),
            fill: LinearGradient(degree: 90, from: Color.white, to: Color.black),
            stroke: Stroke(fill: Color.clear, width: 0.0)
        )
        
        node.contents.append(shp)
        node.contents.append(shpTwo)
        super.init(node: node, coder: aDecoder)
    }
}

public class AnimatedClock: MacawView {
    
    required init?(coder aDecoder: NSCoder) {
        let w = (UIScreen.main.bounds.width / 2)
        let clockimg = Image(
            src: "clock",
            w: Int(w), h: Int(w),
            place: Transform.move(dx: 0, dy: 0)
        )
        
        if let clocked = EmployeeIDEntry.foundUser?.punchedIn {
            if clocked == true {
                clockimg.src = "clockIn"
            } else {
                clockimg.src = "clock_white"
            }
        }
//        let grp = Group(); grp.contents.append(clockimg)
        
        super.init(node: clockimg, coder: aDecoder)
    }
}

public class LongHandAnimated: MacawView {
    required init?(coder aDecoder: NSCoder) {
        let w = (UIScreen.main.bounds.width / 2)
        let ruler = Image(
            src: "clock_longHand",
            w: Int(w / 8), h: Int(w / 2),
            place: Transform.move(dx: 0, dy: 0),
            tag: ["clock_longHand"]
        )
        
        super.init(node: ruler, coder: aDecoder)
    }
}
