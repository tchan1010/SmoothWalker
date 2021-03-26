//
//  WalkingSpeedViewController.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit

public let meterPerSecond = HKUnit(from: "m/s")

class WalkingSpeedViewController: HealthQueryTableViewController {
    
    /// The date from the latest server response.
    private var dateLastUpdated: Date?
    
    private var originalData  = [HealthDataTypeValue]()
    
    /*------------------------------------------------------------------*/
   
    /// MARK:  Handle different display timelines as selected by user
    
    static var displayTimeline = Timeline.daily
    
    func setupTimelineButton() {
       
        let barButtonItem = UIBarButtonItem(title: "Timeline", style: .plain, target: self, action: #selector(didTapShowButton))
            
        navigationItem.leftBarButtonItem = barButtonItem
    }
    
    // MARK: Initializers
    
    init() {
        super.init(dataTypeIdentifier: HKQuantityTypeIdentifier.walkingSpeed.rawValue)
        
        // Set weekly predicate
        queryPredicate = createLastWeekPredicate()
        
        setupTimelineButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Authorization
        if !dataValues.isEmpty { return }
        
        WalkingSpeedViewController.displayTimeline =  restoreUserSelectedTimeline()
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [dataTypeIdentifier]) { (success) in
            if success {
                self.originalData = []
                // Perform the query and reload the data.
                self.loadData()
            }
        }
    }
    
    //
    // change the diesplay timeline as per user
    //
    private func changeTimeline(_ timeline : Timeline)
    {
        if WalkingSpeedViewController.displayTimeline != timeline
        {
            WalkingSpeedViewController.displayTimeline = timeline
            saveUserSelectedTimeline(timeline)
            self.reloadData()
        }
    }
    
    //
    // MARK: - Prompt user to change the display timeline
    //         No need to handle iPad as this app runs on iPhone only
    //
    @objc
    func didTapShowButton() {
        let vc = UIAlertController(title: "SmoothWalker", message: "Select a Display Timeline", preferredStyle: .actionSheet)
        
        for caseItem in Timeline.allCases {
            vc.addAction(
                UIAlertAction(title: caseItem.rawValue, style: .default, handler: { action in
                
                self.changeTimeline(caseItem)
            }))
           
        }
        vc.addAction( UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc
    override func didTapFetchButton() {
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from: serverResponse.date)
            self?.handleServerResponse(serverResponse)
        }
    }
    
    // MARK: - Network
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    override func handleServerResponse(_ serverResponse: ServerResponse) {
        let weeklyReport = serverResponse.weeklyReport
        var index = 0
        let addedSamples = weeklyReport.samples.map { (serverHealthSample) -> HKQuantitySample in
                        
            // Set the sync identifier and version
            var metadata = [String: Any]()
            let sampleSyncIdentifier = String(format: "%@_%@\(index)", weeklyReport.identifier,
                        serverHealthSample.syncIdentifier
                )
            index += 1
    
            metadata[HKMetadataKeySyncIdentifier] = sampleSyncIdentifier
            metadata[HKMetadataKeySyncVersion] = serverHealthSample.syncVersion
            
            // Create HKQuantitySample
            let quantity = HKQuantity(unit: meterPerSecond, doubleValue: serverHealthSample.value / 360.0)
            let sampleType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
            let quantitySample = HKQuantitySample(type: sampleType,
                                                  quantity: quantity,
                                                  start: serverHealthSample.startDate,
                                                  end: serverHealthSample.endDate,
                                                  metadata: metadata)
            
            return quantitySample
        }
        
        HealthData.healthStore.save(addedSamples) { (success, error) in
            if success {
                self.originalData = []
                self.loadData()
            }
        }
    }
    
    //
    // Collect data for weekly average walking speed
    //
    private func setupWeeklyDataValues() {
       
        guard !originalData.isEmpty else {
            return
        }
        dataValues = []
        let calendar: Calendar = .current
        let firstDate = originalData.first!.startDate
        var weekday = calendar.component(.weekday, from: firstDate)
        var startDate : Date?
        var earliestDate : Date?
        var endDate : Date?
        var sum : Double = 0.0
        
        for index in 0..<originalData.count {
            let item = originalData[index]
            let (year,month,day) = extractDate(item.startDate)
            if (startDate == nil) {
                startDate = composeOffsetDate(year,month,day,-weekday)
                if earliestDate == nil {
                    earliestDate = startDate
                    let (year2,month2,day2) = extractDate(startDate!)
                    if (day2 > 7) {
                        addPlaceholderData(year2,month2,day2-7,6)
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
            addPlaceholderData(year2,month2,day2+1,7)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WalkingSpeedViewController.displayTimeline = .daily
    }
    
    //
    // Add a dummy data value for weekly or monthlu averago
    //
    private func addPlaceholderData(_ year : Int,_ month : Int,
                                    _ day : Int = 1, _ offset : Int = -1)
    {
        if (month >= 1 && month <= 12) {
            let date = composeDate(year,month,day)
            let endDate = offset == -1 ? composeDate(year,month,-1) : composeOffsetDate(year,month,day,offset)
            let data = HealthDataTypeValue(startDate:date!, endDate:endDate!,value:0.0)
            dataValues.append(data)
        }
    }
    
    //
    // Collect data for monthly average walking speed
    //
    private func setupMonthlylyDataValues() {
       
        guard !originalData.isEmpty else {
            return
        }
        dataValues = []
        var currentMonth = -1
        var startDate : Date?
        var sum : Double = 0.0
        
        for index in 0..<originalData.count {
            let item = originalData[index]
            let (year,month,_) = extractDate(item.startDate)
            if currentMonth == -1 {
                currentMonth = month
                addPlaceholderData(year,month-1)
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
            addPlaceholderData(year,month+1)
        }
    }
    
    private func setupDataValuesForTimeline() {
        
        switch (WalkingSpeedViewController.displayTimeline) {
        case .daily:
            dataValues = originalData
        case .weekly:
            setupWeeklyDataValues()
            break
        case .monthly:
            setupMonthlylyDataValues()
            break;
        }
    }
    
    // MARK: Function Overrides
    
    override func reloadData() {
        
        if (originalData.isEmpty) {
            originalData = dataValues
        }
        setupDataValuesForTimeline()
        
        super.reloadData()
        
        
        // Change axis to use weekdays for six-minute walk sample
        DispatchQueue.main.async {
            
            var maxY = 0.0;
            self.dataValues.forEach { maxY = max(maxY,$0.value) }
            maxY = maxY < 1.0 ? 1.0 :  round(maxY + 0.8) 
            
            self.chartView.graphView.yMinimum = 0
            self.chartView.graphView.yMaximum = CGFloat(maxY)
            
            if let dateLastUpdated = self.dateLastUpdated {
                self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            }
        }
    }

}
