//
//  FlashControl.swift
//  OCamera
//
//  Created by kegebai on 2018/9/21.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit

let BUTTON_WIDTH : CGFloat = 48.0
let BUTTON_HEIGHT: CGFloat = 30.0
let ICON_WIDTH   : CGFloat = 18.0
let FONT_SIZE    : CGFloat = 17.0

let BOLD_FONT    : UIFont  = UIFont(name: "AvenirNextCondensed-DemiBold", size: FONT_SIZE) ?? UIFont.boldSystemFont(ofSize: FONT_SIZE)
let NORMAL_FONT  : UIFont  = UIFont(name: "AvenirNextCondensed-Medium", size: FONT_SIZE) ?? UIFont.systemFont(ofSize: FONT_SIZE)

@objc protocol FlashControlDelegate {
    @objc optional func flashControlWillExpand()
    @objc optional func flashControlDidExpand()
    @objc optional func flashControlWillCollapse()
    @objc optional func flashControlDidCollapse()
}

class FlashControl: UIControl {
    weak var delegate: FlashControlDelegate?
    
    var selectedMode: Int = 0 {
        didSet { self.sendActions(for: .valueChanged) }
    }
    
    private var selectedIndex: Int = 0 {
        willSet {
            // Remap to fit enum values
            if (newValue == 0) {
                self.selectedMode = 2
            } else if (newValue == 2) {
                self.selectedMode = 0
            }
        }
    }
    
    private var isExpanded   : Bool    = false
    private var defaultWidth : CGFloat = 0.0
    private var expandWidth  : CGFloat = 0.0
    private var middleY      : CGFloat = 0.0
    private var labels       : Array   = Array<UILabel>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setUp()
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 16, y: 0, width: ICON_WIDTH + BUTTON_WIDTH, height: BUTTON_WIDTH))
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FlashControl {
    
    private func setUp() {
        self.backgroundColor = .clear
        let imageView: UIImageView = UIImageView(image: UIImage(named: "flash_control"))
        imageView.y = (self.height - imageView.height) / 2
        self.addSubview(imageView)
        
        self.middleY       = CGFloat(floorf(Float(self.width - BUTTON_HEIGHT)) / 2)
        self.labels        = self.buildLabels(["Auto", "On", "Off"])
        self.defaultWidth  = self.width
        self.expandWidth   = ICON_WIDTH + BUTTON_WIDTH * CGFloat(self.labels.count)
        self.clipsToBounds = true
        
        self.addTarget(self, action: #selector(selectMode(_:forEvent:)), for: .touchUpInside)
    }
    
    @objc private func selectMode(_ sender: Any, forEvent event: UIEvent) {
        
        if (!self.isExpanded) {
            self.performSelectorIfSupported(#selector(FlashControlDelegate.flashControlWillExpand))
            
            UIView.animate(withDuration: 0.3, animations: {
                self.width = self.expandWidth
                for (i, label) in self.labels.enumerated() {
                    label.font  = i == self.selectedIndex ? BOLD_FONT : NORMAL_FONT
                    label.frame = CGRect(x: ICON_WIDTH + CGFloat(i) * BUTTON_WIDTH,
                                         y: self.middleY,
                                     width: BUTTON_WIDTH,
                                    height: BUTTON_HEIGHT)
                    if (i > 0) {
                        label.textAlignment = .center
                    }
                }
            }) { (isFinished) in
                self.performSelectorIfSupported(#selector(FlashControlDelegate.flashControlDidExpand))
            }
        }
        //
        else {
            self.performSelectorIfSupported(#selector(FlashControlDelegate.flashControlWillCollapse))
            let touch: UITouch? = event.allTouches?.randomElement()
            
            for (i, label) in self.labels.enumerated() {
                let touchPoint: CGPoint? = touch?.location(in: label)
                
                if label.point(inside: touchPoint!, with: event) {
                    self.selectedIndex = i
                    label.textAlignment = .left
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        for (i, label) in self.labels.enumerated() {
                            if (i < self.selectedIndex) {
                                label.frame = CGRect(x: ICON_WIDTH,
                                                     y: self.middleY,
                                                 width: 0.0,
                                                height: BUTTON_HEIGHT)
                            }
                            else if (i > self.selectedIndex) {
                                label.frame = CGRect(x: ICON_WIDTH + BUTTON_WIDTH,
                                                     y: 0.0,
                                                 width: 0.0,
                                                height: BUTTON_HEIGHT)
                            }
                            else if (i == self.selectedIndex) {
                                label.frame = CGRect(x: ICON_WIDTH,
                                                     y: self.middleY,
                                                 width: BUTTON_WIDTH,
                                                height: BUTTON_HEIGHT)
                            }
                        }
                        self.width = self.defaultWidth
                    }) { (isFinished) in
                        self.performSelectorIfSupported(#selector(FlashControlDelegate.flashControlDidCollapse))
                    }
                    break
                }
            }
        }
        self.isExpanded = !self.isExpanded
    }
    
    private func buildLabels(_ labelStrings: Array<String>) -> Array<UILabel> {
        var labels: Array<UILabel> = Array<UILabel>()
        var x: CGFloat = ICON_WIDTH
        var first: Bool = true
        
        for string in labelStrings {
            let label: UILabel = UILabel(frame: CGRect(x: x,
                                                       y: self.middleY,
                                                   width: BUTTON_WIDTH,
                                                  height: BUTTON_HEIGHT))
            label.backgroundColor = .clear
            label.textAlignment = first ? .left : .right
            label.textColor = .white
            label.text = string
            label.font = NORMAL_FONT
            self.addSubview(label)
            labels.append(label)
            first = false
            x += BUTTON_WIDTH
        }
        
        return labels;
    }
    
    private func performSelectorIfSupported(_ sel: Selector) {
        if (self.responds(to: sel)) {
            self.perform(sel, with: nil)
        }
    }
}
