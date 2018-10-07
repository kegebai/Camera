//
//  PhotoFilter.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import CoreImage

class PhotoFilter {
    
    static func filterNames() -> [String] {
        return [
            "CIPhotoEffectChrome",
            "CIPhotoEffectFade",
            "CIPhotoEffectInstant",
            "CIPhotoEffectMono",
            "CIPhotoEffectNoir",
            "CIPhotoEffectProcess",
            "CIPhotoEffectTonal",
            "CIPhotoEffectTransfer"
        ]
    }
    
    static func filterDisplayNames() -> [String] {
        var displayNames: [String] = []
        for filterName in self.filterNames() {
            displayNames.append(filterName.matching(regex: "CIPhotoEffect(.*)", capture: 1))
        }
        return displayNames
    }
    
    static func filterFor(displayName: String) -> CIFilter {
        for name in self.filterNames() {
            if name.contains(displayName) {
                return CIFilter(name: name)!
            }
        }
        return self.defaultFilter()
    }
    
    static func defaultFilter() -> CIFilter {
        return CIFilter(name: self.filterNames().first!)!
    }
}
