//
//  WalkingSpeedChartsViewController.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/25/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit

class WalkingSpeedChartsViewController: DataTypeCollectionViewController
{
    let calendar: Calendar = .current
    
    var mobilityContent: [String] = [
        HKQuantityTypeIdentifier.walkingSpeed.rawValue
    ]
    var dateLastUpdated : Date?
    var queryPredicate: NSPredicate?
    
    var originalData = [HealthDataTypeValue]()
    
    var dataValues : [HealthDataTypeValue] = []
    
    var queries: [HKAnchoredObjectQuery] = []
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
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
        
        /*
        // Authorization
        if !queries.isEmpty { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: mobilityContent) { (success) in
            if success {
                //self.setUpBackgroundObservers()
                self.loadData()
            }
        }
        */
        self.loadData()
    }
    
    // MARK: Fetch mock data
    
    func setupBarButtons() {
       
        /*
        let fetchButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(didTapFetchButton))
            
        navigationItem.rightBarButtonItem = fetchButtonItem
        */
 
        let backButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapBackButton))
            
        navigationItem.leftBarButtonItem = backButtonItem
    }
    
    /*
    @objc
    func didTapFetchButton() {
        
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from: serverResponse.date)
            self?.handleServerResponse(serverResponse)
        }
    }
    */
    
    @objc
    func didTapBackButton() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Network
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    /*
    func handleServerResponse(_ serverResponse: ServerResponse) {
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
            // convert six-minute walking distance to walking speed
            let quantity = HKQuantity(unit: meterPerSecond, doubleValue: serverHealthSample.value / 360.0)
            let sampleType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
            let quantitySample = HKQuantitySample(type: sampleType,
                                                  quantity: quantity,
                                                  start: serverHealthSample.startDate,
                                                  end: serverHealthSample.endDate,
                                                  metadata: metadata)
            
            let healthData = HealthDataTypeValue(
                startDate: serverHealthSample.startDate,
                endDate: serverHealthSample.endDate,
                value:serverHealthSample.value / 360.0)
            
            self.originalData.append(healthData)
            
            return quantitySample
        }
        
        HealthData.healthStore.save(addedSamples) { (success, error) in
            if success {
                //self.originalData = []
                self.loadData()
            }
        }
    }
    */
    // MARK: - Data Functions
    
    func loadData() {
        performQuery {
            // Dispatch UI updates to the main thread.
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }

    /*
    func setUpBackgroundObservers() {
        data.compactMap { getSampleType(for: $0.dataTypeIdentifier) }.forEach { (sampleType) in
            createAnchoredObjectQuery(for: sampleType)
        }
    }
    
    func createAnchoredObjectQuery(for sampleType: HKSampleType) {
        // Customize query parameters
        let predicate = createLastWeekPredicate()
        let limit = HKObjectQueryNoLimit
        
        // Fetch anchor persisted in memory
        let anchor = HealthData.getAnchor(for: sampleType)
        
        // Create HKAnchoredObjecyQuery
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: predicate, anchor: anchor, limit: limit) {
            (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        // Create update handler for long-running background query
        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            // The results come back on an anonymous background queue.
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        HealthData.healthStore.execute(query)
        queries.append(query)
    }
    */
    
    // MARK: Data Functions

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
    

    func performQuery(completion: @escaping () -> Void) {
        var timeStamp : String = ""
        for index in 0..<data.count {
            switch (index) {
            case 0:
                let (values,labels,ts) = setupDailyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = ts
                timeStamp = ts
            case 1:
                let (values,labels) = setupWeeklyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = timeStamp
            default:
                let (values,labels) = setupMonthlyDataValues()
                self.data[index].values = values
                self.data[index].labels = labels
                self.data[index].timeStamp = timeStamp
            }
        }
        completion()
    }
    /*
    func performQuery(completion: @escaping () -> Void) {
        // Create a query for each data type.
        for (index, item) in data.enumerated() {
            // Set dates
            let now = Date()
            let startDate = getLastWeekStartDate()
            let endDate = now
            
            let predicate = createLastWeekPredicate()
            let dateInterval = DateComponents(day: 1)
            
            // Process data.
            let statisticsOptions = getStatisticsOptions(for: item.dataTypeIdentifier)
            let initialResultsHandler: (HKStatisticsCollection) -> Void = { (statisticsCollection) in
                var values: [Double] = []
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                    let statisticsQuantity = getStatisticsQuantity(for: statistics, with: statisticsOptions)
                    if let unit = preferredUnit(for: item.dataTypeIdentifier),
                        let value = statisticsQuantity?.doubleValue(for: unit) {
                        values.append(value)
                    }
                }
                self.data[index].values = values
                
                completion()
            }
            
            // Fetch statistics.
            HealthData.fetchStatistics(with: HKQuantityTypeIdentifier(rawValue: item.dataTypeIdentifier),
                                       predicate: predicate,
                                       options: statisticsOptions,
                                       startDate: startDate,
                                       interval: dateInterval,
                                       completion: initialResultsHandler)
        }
    }
    */
}
