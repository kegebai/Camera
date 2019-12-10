//
//  ArrayExtention.swift
//  OCamera
//
//  Created by kegebai on 2019/12/5.
//  Copyright © 2019 kegebai. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
 
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
