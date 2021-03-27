//
//  WalkingSpeedChartsViewController.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/25/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit

//
// class to display daily, weekly and monthly average walking speed charts
// all in one view
//
class WalkingSpeedChartsViewController: DataTypeCollectionViewController
{
    var mobilityContent: [String] = [
        HKQuantityTypeIdentifier.walkingSpeed.rawValue
    ]
    var dateLastUpdated : Date?
    var queryPredicate: NSPredicate?
    
    // Data passed in from WalkingSpeedViewController
    var originalData = [HealthDataTypeValue]()
    
    var dataValues : [HealthDataTypeValue] = []
    
    var queries: [HKAnchoredObjectQuery] = []
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        // scale factor to fit all three charts in one screen
        scaleCellHeight = 0.7
        
        super.viewDidLoad()
        
        data = [ (mobilityContent[0], [], [], nil), // daily
                 (mobilityContent[0], [], [], nil), // weekly
                 (mobilityContent[0], [], [], nil)  // monthly
               ]
        
        self.dateLastUpdated = Date()
        
        setupBarButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    // MARK: UI button setup
    
    func setupBarButtons() {
 
        let backButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapBackButton))
            
        navigationItem.leftBarButtonItem = backButtonItem
    }
    
    @objc
    func didTapBackButton() {
        
        self.dismiss(animated: true, completion: nil)
    }
   
    // MARK: - Data Functions
    
    func loadData() {
        performQuery {
            // Dispatch UI updates to the main thread.
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }

    //
    // Collect data for daily average walking speed
    //
    private func setupDailyDataValues() -> ([Double], [String], String)
    {
        guard !originalData.isEmpty else {
            return ( [], [], "" )
        }
       
        let (year,month,day) = extractDate(originalData.first!.startDate)
        let (year2,month2,day2) = extractDate(originalData.last!.endDate)
        let timeStamp = monthTitles[month-1] + " \(day)" +
               (year == year2 ? "" : ", \(year)") + " - " +
                monthTitles[month2-1] + " \(day2), \(year)"
        let values = originalData.map{ $0.value }
        let labels : [String] = originalData.map {
            let (_,month,day) = extractDate($0.startDate)
            return "\(month)/\(day)"
        }
        return (values, labels, timeStamp)
    }
    
    //
    // Collect data for weekly average walking speed
    //
    private func setupWeeklyDataValues() -> ([Double], [String]) {
       
        let dataValues = xlateWeeklyDataValues(originalData)
        let values : [Double] = dataValues.map{ $0.value }
        let labels : [String] = dataValues.map{
            let (_,month,day) = extractDate($0.startDate)
            return "\(month)/\(day)"
        }
        return (values,labels)
    }
    
    //
    // Collect data for monthly average walking speed
    //
    private func setupMonthlyDataValues() -> ([Double], [String])
    {
        let dataValues = xlateMonthlyDataValues(originalData)
        let values : [Double] = dataValues.map{ $0.value }
        let labels : [String] = dataValues.map{
            monthTitles[extractDate($0.startDate).month-1]
        }
        return (values,labels)
    }
    
    //
    // Collect data for charts
    //
    func performQuery(completion: @escaping () -> Void) {
        var timeStamp : String = ""
        for index in 0..<data.count {
            switch (index) {
            case 0: // for daily walking speed chart
                let (values,labels,ts) = setupDailyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = ts
                timeStamp = ts
            case 1: // for weekly walking speed chart
                let (values,labels) = setupWeeklyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = timeStamp
            default: // for monthly walking speed chart
                let (values,labels) = setupMonthlyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = timeStamp
            }
        }
        completion()
    }
}
