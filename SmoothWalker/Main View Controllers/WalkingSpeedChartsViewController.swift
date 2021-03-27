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
    let dataTypeIdentifier = HKQuantityTypeIdentifier.walkingSpeed.rawValue
    var dateLastUpdated : Date?
    var queryPredicate: NSPredicate?
    var queryAnchor: HKQueryAnchor?
    var queryLimit = HKObjectQueryNoLimit
    
    // Data passed in from WalkingSpeedViewController
    var originalData = [HealthDataTypeValue]()
    
    var dataValues : [HealthDataTypeValue] = []
    
    var queries: [HKAnchoredObjectQuery] = []
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        // scale factor to fit all three charts in one screen
        scaleCellHeight = 0.625
        
        super.viewDidLoad()
        
        data = [ (mobilityContent[0], [], [], nil), // daily
                 (mobilityContent[0], [], [], nil), // weekly
                 (mobilityContent[0], [], [], nil)  // monthly
               ]
        
        self.dateLastUpdated = Date()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !originalData.isEmpty { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [dataTypeIdentifier]) { [self] (success) in
            if success {
                
                if !self.originalData.isEmpty {
                    //self.originalData = []
                    // Perform the query and reload the data.
                    self.loadData()
                }
                else {
                    self.fetchMockedData()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        WalkingSpeedViewController.displayTimeline = .daily
    }
    
    // MARK: Network
    
    // fetch Mock data and load to Health Store
    private func fetchMockedData() {
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from: serverResponse.date)
            self?.handleServerResponse(serverResponse)
        }
    }
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    private func handleServerResponse(_ serverResponse: ServerResponse) {
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
                //self.originalData = []
                self.loadData()
            }
            else if let error = error {
                DispatchQueue.main.async {
                    showMsg(self,"Access Health Store failed (Error: \(error.localizedDescription)). If you have previously denied the app access to the Health Store's Walking Speed data, please authorize the app access to that category in the Health app; otherwise please visit the Welcome page and allow authorization of all categories, including the Walking Speed")
                }
            }
        }
    }
   
    // MARK: - Data Functions
    
    func loadData() {
        
        self.dataValues = []
        
        performQuery {
            if !self.dataValues.isEmpty {
                self.originalData = self.dataValues
                self.setupChartsData {
                    // Dispatch UI updates to the main thread.
                    DispatchQueue.main.async { [weak self] in
                        self?.reloadData()
                    }
                }
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
        guard let sampleType = getSampleType(for: dataTypeIdentifier) else { return }
        
        let anchoredObjectQuery = HKAnchoredObjectQuery(type: sampleType,
                                predicate: queryPredicate,
                                anchor: queryAnchor,
                                limit: queryLimit) {
            (query, samplesOrNil, deletedObjectsOrNil, anchor, errorOrNil) in
            
            guard let samples = samplesOrNil else { return }
            
            self.dataValues = samples.map { (sample) -> HealthDataTypeValue in
                var dataValue = HealthDataTypeValue(startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: .zero)
                if let quantitySample = sample as? HKQuantitySample,
                   let unit = preferredUnit(for: quantitySample) {
                    dataValue.value = quantitySample.quantity.doubleValue(for: unit)
                }
                
                return dataValue
            }
            
            completion()
        }
        
        HealthData.healthStore.execute(anchoredObjectQuery)
    }
    
    func setupChartsData( completion : @escaping () -> Void) {
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
    
    // MARK: handle user selection of chart
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        
        guard !originalData.isEmpty else {
              return
        }
        
        let detailedView = WalkingSpeedViewController()
        detailedView.dataValues = originalData
        WalkingSpeedViewController.displayTimeline =
            indexPath.row == 0 ? .daily :
            indexPath.row == 1 ? .weekly : .monthly
        self.present(detailedView, animated: true, completion: nil)
    }
}
