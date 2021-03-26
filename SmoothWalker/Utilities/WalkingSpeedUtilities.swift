//
//  WalkingSpeedUtilities.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/26/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import Foundation
import HealthKit

//
// -------------------------------------------------------------------------
// Walking speed HKUnit
//
let meterPerSecond = HKUnit(from: "m/s")

//
// -------------------------------------------------------------------------
// Utilities to handle the display of different
// walking speed timelines
//
enum Timeline : String, CaseIterable  {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

fileprivate let DISPLAY_TIMELINE = "DisplayTimeLine"

//
// save user-selected display timeline for walking speed
//
func saveUserSelectedTimeline(_ timeline : Timeline) {
    
    UserDefaults.standard.set(timeline.rawValue, forKey:DISPLAY_TIMELINE)
}

//
// restore any user-selected display timeline for walking speed
//
func restoreUserSelectedTimeline() -> Timeline {
    
    /* restore the last user-selected display timeline */
    if let strTimeline = UserDefaults.standard.string(forKey:DISPLAY_TIMELINE) {
        return Timeline(rawValue: strTimeline) ?? .daily
    }
    return .daily
}

//
// -------------------------------------------------------------------------
//  Utilities constants and functions for date processing
//

let monthTitles = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
//
// Maximum days of each calendar month, leap year is checked in maxDaysOfMonth()
//
fileprivate let daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

//
// Extract month, day and year from a given Date object
//
func extractDate(_ inDate : Date ) -> (year : Int, month : Int, day : Int)
{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if let results = dateFormatter.string(for:inDate)?.components(separatedBy: "-"),
       results.count == 3,
       let year = Int(results[0]), let month = Int(results[1]), let day = Int(results[2])
    {
          return (year,month,day)
    }
    return (-1,-1,-1)
}

//
// Check if a given year is a leap year
//
private func leapYear(_ year : Int) -> Bool {

    if year % 400 == 0 {
        return true
    }
    return year % 100 != 0 && year % 4 == 0 ? true : false
}

//
// Return the max days of the given month, take into account of leap year
//
func maxDaysOfMonth(_ month : Int, _ year : Int) -> Int {

    return month == 2 && leapYear(year) ? 29 : daysPerMonth[month-1]
}

//
// Create a Date object from the given year, month and day
//
func composeDate(_ year : Int, _ month : Int, _ day : Int) -> Date?
{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let newDay = day == -1 ? maxDaysOfMonth(month,year) : day
    return dateFormatter.date(from: "\(year)-\(month)-\(newDay)")
}

//
// Return a Date object based on the given year,month.day and offset days
// the offset can be a positive or negative number
//
func composeOffsetDate(_ year : Int, _ month : Int,
                       _ day : Int,_ offset : Int) -> Date?
{
    var newDay = day + offset

    if newDay > maxDaysOfMonth(month,year) {
        newDay -= maxDaysOfMonth(month,year)
        let newMonth = month + 1
        if newMonth > 12 {
            return composeDate(year+1,1,newDay)
        }
        return composeDate(year,newMonth,newDay)
    }
    else if newDay <= 0 {
        var newYear = year
        var newMonth = month - 1
        if newMonth == 0  {
            newMonth = 12
            newYear -= 1
        }
        newDay = maxDaysOfMonth(newMonth,newYear) - newDay
        return composeDate(newYear,newMonth,newDay)
    }
    return composeDate(year,month,newDay)
}

//
// -------------------------------------------------------------------------
// Utility functions to translate weekly and monthly walking speed from daily
// walking speed data
//

//
// Add a dummy data value for weekly or monthly averago
//
private func addPlaceholderData(_ year : Int,_ month : Int,
    _ day : Int, _ offset : Int, _ dataValues : inout [HealthDataTypeValue])
{
    if (month >= 1 && month <= 12) {
        if let date = composeDate(year,month,day),
           let endDate = offset == -1 ? composeDate(year,month,-1) : composeOffsetDate(year,month,day,offset)
        {
            dataValues.append( HealthDataTypeValue(startDate:date, endDate:endDate,value:0.0))
        }
    }
}

//
// xlate daily walking speed data to weekly walking speed
//
func xlateWeeklyDataValues(_ rawData : [HealthDataTypeValue]) -> [HealthDataTypeValue]
{
    var dataValues = [HealthDataTypeValue]()
    
    guard !rawData.isEmpty else {
        return dataValues
    }
   
    let calendar: Calendar = .current
    let firstDate = rawData.first!.startDate
    var weekday = calendar.component(.weekday, from: firstDate)
    var startDate : Date?
    var earliestDate : Date?
    var endDate : Date?
    var sum : Double = 0.0
    
    for index in 0..<rawData.count {
        let item = rawData[index]
        let (year,month,day) = extractDate(item.startDate)
        if (startDate == nil) {
            startDate = composeOffsetDate(year,month,day,-weekday)
            if earliestDate == nil {
                earliestDate = startDate
                let (year2,month2,day2) = extractDate(startDate!)
                if (day2 > 7) {
                    addPlaceholderData(year2,month2,day2-7,6,&dataValues)
                }
            }
        }
        sum += item.value
        endDate = item.endDate
        weekday += 1
        if weekday >= 7 {
            weekday = 0
            let data = HealthDataTypeValue(startDate:startDate!, endDate:item.endDate,value:sum/7.0)
            dataValues.append(data)
            sum = 0.0
            startDate = nil
        }
    }
    if startDate != nil {
        let offset = 7 - weekday
        let (year,month,day) = extractDate(endDate!)
        endDate = composeOffsetDate(year,month,day,offset)
        let data = HealthDataTypeValue(startDate:startDate!, endDate:endDate!,value:sum/7.0)
        dataValues.append(data)
        let (year2,month2,day2) = extractDate(endDate!)
        addPlaceholderData(year2,month2,day2+1,7,&dataValues)
    }
    return dataValues
}

//
// Translate daily walking speed data to monthly walking speed
//
func xlateMonthlyDataValues(_ rawData : [HealthDataTypeValue]) ->
               [HealthDataTypeValue]
{
    var dataValues = [HealthDataTypeValue]()
    
    guard !rawData.isEmpty else {
        return dataValues
    }
    
    var currentMonth = -1
    var startDate : Date?
    var sum : Double = 0.0
    
    for index in 0..<rawData.count {
        let item = rawData[index]
        let (year,month,_) = extractDate(item.startDate)
        if currentMonth == -1 {
            currentMonth = month
            addPlaceholderData(year,month-1,1,-1,&dataValues)
        }
        else if currentMonth != month {
            if startDate != nil {
                let endDate = composeDate(year,currentMonth,-1)
                let data = HealthDataTypeValue(startDate:startDate!, endDate:endDate!,value:sum/Double(maxDaysOfMonth(currentMonth,year)))
                dataValues.append(data)
            }
            sum = 0.0
            startDate = nil
            currentMonth = month
        }
        if (startDate == nil) {
            startDate = composeDate(year,month,1)
        }
        sum += item.value
    }
    if startDate != nil {
        let (year,month,_) = extractDate(startDate!)
        let endDate = composeDate(year,month,-1)
        let data = HealthDataTypeValue(startDate:startDate!, endDate:endDate!,value:sum/Double(maxDaysOfMonth(month,year)))
        dataValues.append(data)
        addPlaceholderData(year,month+1,1,-1,&dataValues)
    }
    return dataValues
}

//
// -------------------------------------------------------------------------
// Misc
//

func showMsg(_ caller : UIViewController, _ msg : String) {
    
    let alert = UIAlertController(title: "SmoothWalker", message: msg, preferredStyle: .alert)
    
    alert.addAction( UIAlertAction(title: "OK", style: .cancel, handler: nil) )
    
    caller.present(alert, animated: true, completion: nil)
}
