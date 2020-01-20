//
//  Utils.swift
//  IOS-Memory-Storage
//
//  Created by michsien on 20/01/2020.
//  Copyright © 2020 Michał Sieńczak. All rights reserved.
//

import Foundation

struct Utils {
    
    static let SensorsCount = 20
    static let ReadingsCount = 100000
    
    static func generateRandTimestamp() -> Int {
        let current = Int(Date().timeIntervalSince1970)
        let randomIntervalLessThanAYear = Int.random(in: 0 ..< 31556926)
        let random = current - randomIntervalLessThanAYear;
        return random
    }
    
    static func formatDate(_ date: Date?) -> String {
        if let d = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: d)
            return dateString
        } else {
            return "Invalid date"
        }
    }
    
    static func generateRandomDate(daysBack: Int) -> Date? {
        let day = arc4random_uniform(UInt32(daysBack))+1
        let hour = arc4random_uniform(23);
        let minute = arc4random_uniform(59);
        
        let today = Date(timeIntervalSinceNow: 0);
        let gregorian = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian);
        var offsetComponents = DateComponents();
        offsetComponents.day = -1 * Int(day - 1);
        offsetComponents.hour = -1 * Int(hour);
        offsetComponents.minute = -1 * Int(minute);
        
        let randomDate = gregorian?.date(byAdding: offsetComponents, to: today, options: .init(rawValue: 0))
        return randomDate
    }
    
}
