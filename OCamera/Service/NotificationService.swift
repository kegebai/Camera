//
//  NotificationService.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

enum NotificationService: String {
    case GeneraterThumbnail
    case FilterSelectionChanged
    
    var name: NSNotification.Name { return NSNotification.Name(stringValue) }
    var stringValue: String { return "OCamera" + rawValue }
}

extension NotificationCenter {
    static func post(notification service: NotificationService, object: Any? = nil) {
        NotificationCenter.default.post(name: service.name, object: object)
    }
    
    static func observe(_ observer: Any, notification service: NotificationService, selector: Selector, object: Any? = nil) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: service.name, object: object)
    }
}

//extension Reactive where Base: NotificationCenter {
//    func notification(custom service: NotificationService, object: AnyObject? = nil) -> Observable<Notification> {
//        return notification(service.name, object: object)
//    }
//}
