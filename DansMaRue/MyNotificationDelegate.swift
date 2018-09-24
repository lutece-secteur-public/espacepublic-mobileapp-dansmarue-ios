//
//  NotificationDelegate.swift
//  QuickStart
//
//  Created by Connecthings on 09/11/2017.
//  Copyright © 2017 R&D connecthings. All rights reserved.
//
/*
import Foundation
import UserNotifications
import AdtagLocationDetection

public class MyNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let adtagPlaceManager: AdtagPlaceDetectionManager
    
    public init(_ adtagPlaceManager: AdtagPlaceDetectionManager) {
        self.adtagPlaceManager = adtagPlaceManager
        super.init()
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        adtagPlaceManager.didReceivePlaceNotification(response.notification.request.content.userInfo)
    }
}*/
