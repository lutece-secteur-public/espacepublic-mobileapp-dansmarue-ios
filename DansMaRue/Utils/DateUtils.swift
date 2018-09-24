//
//  DateUtils.swift
//  DansMaRue
//
//  Created by Xavier NOEL on 03/05/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import Foundation

class DateUtils {
    
    static let formatDate = "yyyy.MM.dd"
    static let formatHour = "HH:mm"
    
    static let formatDateHour = "yyyy.MM.dd HH:mm"
    
    class func formatDateByLocal(dateString: String) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = formatDate
        
        let itemDate = dateFormater.date(from: dateString)
        return DateFormatter.localizedString(from: itemDate!, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.none)
    }
    
    class func stringDate(from date: Date) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = formatDate
        
        return dateFormater.string(from: date)
    }
    
    class func stringHour(from date: Date) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = formatHour
        
        return dateFormater.string(from: date)
    }
    
    class func date(fromDate date: String, hour: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatDateHour
        return dateFormatter.date(from: "\(date) \(hour)")!

    }
    
    class func displayDuration(fromDate date: String, hour: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatDateHour
        if let date = dateFormatter.date(from: "\(date) \(hour)") {
            let days = Date().days(from: date)
            if days > 7 {
                return "Il y a plus d'une semaine"
            } else if days == 0 {
                let hours = Date().hours(from: date)
                if hours > 0 {
                    return "Il y a \(hours) heure(s)"
                } else  {
                    let minutes = Date().minutes(from: date)
                    if minutes > 0 {
                        return "Il y a \(minutes) minute(s)"
                    } else {
                        return "A l'instant"
                    }
                }
            } else {
                return "Il y a \(days) jour(s)"
            }
        }
        
        return ""
    }
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}
