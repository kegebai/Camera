//
//  StringExtention.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

extension String {
    
    func matching(regex: String, capture: Int) -> String {
        
        let expression: NSRegularExpression = try! NSRegularExpression(pattern: regex, options: .init(rawValue: 0))
        let result: NSTextCheckingResult = expression.firstMatch(in: self,
                                                                 options: .init(rawValue: 0),
                                                                 range: NSRange(location: 0, length: self.count))!
        
        guard capture < result.numberOfRanges else { return "" }
        
        return self.substring(with: Range(result.range(at: capture), in: self)!)
    }
}
