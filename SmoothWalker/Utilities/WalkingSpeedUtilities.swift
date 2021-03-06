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
// This file contains utility functions and data to support
// the gathering and display of daily, weekly and monthly
// walking speed charts and tables.
//
// -------------------------------------------------------------------------
// Walking speed HKUnit
//
let meterPerSecond = HKUnit(from: "m/s")
let WEEK_SUFFIX = " wk"

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

struct HealthDataValueTemp {
    var startDate : Date
    var endDate   : Date
    var valueSum   : (Double,Int)
}
//
// -------------------------------------------------------------------------

//
//  Calendar month titles
//
let monthTitles = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
//
// Maximum days of each calendar month (leap year is handled separately)
//
fileprivate let daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

//
// Extract month, day and year from a given date
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
// Check a given year is a leap year
//
private func leapYear(_ year : Int) -> Bool {

     (year % 400 == 0) || (year % 100 != 0 && year % 4 == 0)
}

//
// Return the max days of a given month, take into account of leap year
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
                       _ day : Int,  _ offset : Int) -> Date?
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
        newDay = maxDaysOfMonth(newMonth,newYear) + newDay
        return composeDate(newYear,newMonth,newDay)
    }
    return composeDate(year,month,newDay)
}

//
// -------------------------------------------------------------------------
// Utility functions to compose weekly and monthly walking speed data
// from the daily walking speed data
//

//
// Add a dummy data record for weekly and monthly charts
//
private func addPlaceholderData(_ year : Int, _ month : Int,
                                _ day : Int,  _ offset : Int,
                          _ dataValues : inout [HealthDataTypeValue])
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
// Check a data is in the weekly range of any bucket, and update value
//
private func findAddItemValue(_ data : HealthDataTypeValue,_ dataValues : inout [HealthDataValueTemp]) -> Bool
{
    for (pos,item) in dataValues.enumerated().reversed() {
        
        if  data.startDate >= item.startDate &&
            data.startDate <= item.endDate
        {
            dataValues[pos].valueSum.0 += data.value
            dataValues[pos].valueSum.1 += 1
            return true
        }
    }
    return false
}

//
// Translate daily walking speed data to weekly walking speed data
//
func xlateWeeklyDataValues(_ rawData : [HealthDataTypeValue]) -> [HealthDataTypeValue]
{
    var dataValues = [HealthDataTypeValue]()
    var tmpValues = [HealthDataValueTemp]()
    
    let calendar: Calendar = .current
    
    rawData.forEach {
    
        if !findAddItemValue($0,&tmpValues) {
            
            // create a new bucket for a calendar week
            
            let (year,month,day) = extractDate($0.startDate)
          
            let weekday = calendar.component(.weekday, from: $0.startDate)
            
            var firstWeekDate = composeOffsetDate(year,month,day,-weekday+1)
            
            if firstWeekDate == nil {
                print("**** Got firstWeekDate failed!")
                firstWeekDate = $0.startDate
            }
            
            let lastWeekDate = composeOffsetDate(year,month,day,7-weekday)!
            
            let data = HealthDataValueTemp(startDate: firstWeekDate!, endDate: lastWeekDate, valueSum: ($0.value,1) )
            
            tmpValues.append(data)
        }
    }
    
    tmpValues.forEach {
        let dataVal = HealthDataTypeValue( startDate: $0.startDate,
                                           endDate: $0.endDate,
                                           value: $0.valueSum.0 / Double($0.valueSum.1)
                                        )
        dataValues.append(dataVal)
    }
    
    // Optional: make the chart looks pretty
    if !dataValues.isEmpty && dataValues.count <= 2 {
        
        dataValues.sort{ $0.startDate < $1.startDate }
        
        // add a dummy week at the start of list
        var placeholder = [HealthDataTypeValue]()
        let (year,month,day) = extractDate(dataValues.first!.startDate)
        addPlaceholderData(year,month,day-7,6,&placeholder)
        dataValues = placeholder + dataValues
        
        // add a dummy week at the end of list
        let (year2,month2,day2) = extractDate(dataValues.last!.endDate)
        addPlaceholderData(year2,month2,day2+1,6,&dataValues)
    }
    
    return dataValues
}

//
// Create a date range time stamp for all charts
//
func getChartTimeStamp(_ dataValues : [HealthDataTypeValue]) -> String?
{
    var startDate, endDate : Date?
    dataValues.forEach {
        if $0.value > 0.0 {
            if startDate == nil {
                startDate = $0.startDate
            }
            endDate = $0.endDate
        }
    }
    if startDate != nil && endDate != nil {
        let (year,month,day) = extractDate(startDate!)
        let (year2,month2,day2) = extractDate(endDate!)
        return monthTitles[month-1] + " \(day)" +
               (year == year2 ? "" : ", \(year)") + " - " +
            (month == month2 && year == year2 ? "" : monthTitles[month2-1] + " ") + "\(day2), \(year)"
    }
    return nil
}

//
// Translate daily walking speed data to monthly walking speed data
//
func xlateMonthlyDataValues(_ rawData : [HealthDataTypeValue]) ->
               [HealthDataTypeValue]
{
    var dataValues = [HealthDataTypeValue]()
    
    var xlateMap = [String:(Double,Int)]()
    
    rawData.forEach {
        let (year,month,_) = extractDate($0.startDate)
        let key = "\(year)-\(month)"
        if let (value,sum) = xlateMap[key] {
            xlateMap[key] = (value + $0.value, sum + 1)
        }
        else {
            xlateMap[key] = ($0.value, 1)
        }
    }
    
    for (key,sum) in xlateMap {
        let timeStamp = key.components(separatedBy: "-")
        if let year = Int(timeStamp[0]),
           let month = Int(timeStamp[1])
        {
            let startDate = composeDate(year,month,1)
            let endDate = composeDate(year,month,-1)
            let data = HealthDataTypeValue(startDate:startDate!, endDate:endDate!,value:sum.0/Double(sum.1))
            dataValues.append(data)
        }
    }
    
    
    // HashMap is not sorted
    dataValues.sort { $0.startDate < $1.startDate }
    
    // Optional: add dummy month records before and after to make
    // the chart looks pretty
    
    if (dataValues.count <= 2) {
        var tmp = [HealthDataTypeValue]()
        let (year,month,_) = extractDate(dataValues.first!.startDate)
        addPlaceholderData(year,month-1,1,-1,&tmp)
        tmp += dataValues
        let (year2,month2,_) = extractDate(dataValues.last!.endDate)
        addPlaceholderData(year2,month2+1,1,-1,&tmp)
        return tmp
    }
    
    return dataValues
}

//
// -------------------------------------------------------------------------
//
// Compute the nearest value higher than the given target value
//
func computeMaxValue(_ targetValue : Double) -> CGFloat
{
    CGFloat(Double(((Int(targetValue * 100.0) / 25) + 1)) * 0.25)
}
