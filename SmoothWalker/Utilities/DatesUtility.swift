//
//  DatesUtility.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/25/21.
//  Copyright © 2021 Apple. All rights reserved.
//
//  A set of utility functions to extract from and create Date objects
//

import Foundation

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
