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
// Class to display the daily, weekly and monthly average walking
// speed charts in one view
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
    
    var fetchButton : UIBarButtonItem?
    
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
    
    private func turnOnOffFetchButton(_ turnOn : Bool) {
        
        DispatchQueue.main.async {
            if turnOn {
                if self.fetchButton == nil {
                    self.fetchButton = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(self.fetchMockedData))
            
                    self.navigationItem.rightBarButtonItem = self.fetchButton!
                }
            }
            else if self.fetchButton != nil {
                self.fetchButton = nil
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    // MARK: Network
    
    //
    // convert multiple health records of the same date
    // into a single health record
    //
    private func compactDataValues(_ dataValues : inout [HealthDataTypeValue])
    {
        for i in 1..<dataValues.count {
            if dataValues[i-1].startDate == dataValues[i].startDate {
                dataValues[i].value += dataValues[i-1].value
                dataValues[i-1].value = 0
            }
        }
        dataValues = dataValues.filter{ $0.value > 0 }
    }
    
    // fetch Mock data and load to Health store
    @objc
    private func fetchMockedData() {
        
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from:Date())
            self?.handleServerResponse(serverResponse)
        }
    }
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    private func handleServerResponse(_ serverResponse: ServerResponse) {
        let weeklyReport = serverResponse.weeklyReport
        let addedSamples = weeklyReport.samples.map { (serverHealthSample) -> HKQuantitySample in
                        
            // Set the sync identifier and version
            var metadata = [String: Any]()
            let sampleSyncIdentifier = String(format: "%@_%@", weeklyReport.identifier,
                        serverHealthSample.syncIdentifier
                )
    
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
                self.loadData()
            }
            else if let error = error {
                DispatchQueue.main.async {
                    self.showMsgAction(msg:"Access Health store failed (Error: \(error.localizedDescription)). If you have denied the app access to the Health store's Walking Speed data, you may authorize the app to have access to that category in the Health app. You may click the Settings button to access the Health app in the Settings app.")
                    self.turnOnOffFetchButton(true)
                }
            }
        }
    }
    
    func showMsgAction( msg : String) {
        let vc = UIAlertController(title: "SmoothWalker", message: msg, preferredStyle: .alert)
        
        vc.addAction( UIAlertAction(title: "OK", style:.cancel, handler: nil))
        
        vc.addAction( UIAlertAction(title: "Settings", style: .default, handler: { action in
            
            self.openSettings()
            
        }))
        self.present(vc, animated:true, completion: nil)
    }
    
    // direct user to the Settings app
    private func openSettings() {
        
        let url = URL(string:UIApplication.openSettingsURLString)
        if UIApplication.shared.canOpenURL(url!){
                // can open succeeded.. opening the url
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
   
    // MARK: - Data Functions
    
    func loadData() {
        
        self.dataValues = []
        self.turnOnOffFetchButton(false)
        
        performQuery {
            if !self.dataValues.isEmpty {
                self.originalData = self.dataValues
                self.setupChartsData {
                    // Dispatch UI updates in the main thread.
                    DispatchQueue.main.async { [weak self] in
                        self?.reloadData()
                    }
                }
            }
        }
    }

    //
    // Collect data for daily average walking speed
    // caller has checked originalData contains data
    //
    private func setupDailyDataValues(_ dataItem : inout (dataTypeIdentifier: String, values: [Double], labels: [String], timeStamp : String?), _ timeStamp : inout String)
    {
        timeStamp = getChartTimeStamp(originalData)!
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
               (
                   originalData.map{ Double($0.value) },
                   originalData.map{
                       let (_,month,day) = extractDate($0.startDate)
                       return "\(month)/\(day)" },
                   timeStamp
               )
     }
    
    //
    // Collect data for weekly average walking speed
    //
    private func setupWeeklyDataValues(_ dataItem : inout (dataTypeIdentifier: String, values: [Double], labels: [String], timeStamp : String?), _ timeStamp :  String)
    {
        let dataValues = xlateWeeklyDataValues(originalData)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        
        let timeStamp2 = getChartTimeStamp(dataValues) ?? timeStamp
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
            (
                dataValues.map { $0.value },
                dataValues.map{
                      dateFormatter.string(from:$0.startDate) + "-" +
                      dateFormatter.string(from:$0.endDate) },
                timeStamp2
            )
    }
    
    //
    // Collect data for monthly average walking speed
    //
    private func setupMonthlyDataValues(_ dataItem : inout (dataTypeIdentifier: String, values: [Double], labels: [String], timeStamp : String?), _ timeStamp :  String)
    {
        let dataValues = xlateMonthlyDataValues(originalData)
        
        let timeStamp2 = getChartTimeStamp(dataValues) ?? timeStamp
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
             (
                  dataValues.map{ $0.value },
                  dataValues.map{
                      monthTitles[extractDate($0.startDate).month-1]},
                  timeStamp2
             )
    }
    
    //
    // Collect data from Health store
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
                var dataValue = HealthDataTypeValue(
                    startDate: self.simpleDate(sample.startDate),
                    endDate: self.simpleDate(sample.endDate),
                    value: .zero)
                if let quantitySample = sample as? HKQuantitySample,
                   let unit = preferredUnit(for: quantitySample) {
                    dataValue.value = quantitySample.quantity.doubleValue(for: unit)
                }
                
                return dataValue
            }
            
            self.compactDataValues(&self.dataValues)
            
            completion()
        }
        
        HealthData.healthStore.execute(anchoredObjectQuery)
    }
    
    // Override the hr:min:sec in the provided date
    // to facilitate the xlation of daily data to weekly date
    //
    func simpleDate(_ old : Date) -> Date {
        let (year,month,day) = extractDate(old)
        return composeDate(year,month,day)!
    }
    
    // Collect data, labels and time stamp for
    // daily, weekly and monthly charts
    //
    func setupChartsData( completion : @escaping () -> Void) {
     
        if  !originalData.isEmpty  {
            
            var timeStamp : String = ""
       
            setupDailyDataValues(&data[0],&timeStamp)
            setupWeeklyDataValues(&data[1],timeStamp)
            setupMonthlyDataValues(&data[2],timeStamp)
        }

        completion()
    }
    
    // MARK: handle user selection of chart
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        
        guard !originalData.isEmpty else {
            self.showMsgAction(msg:"No walking speed data. If you have denied the app access to the Health store's Walking Speed data, you may authorize the app to have access to that category in the Health app. You may click the Settings button to access the Health app in the Settings app.")
              return
        }
        
        // Show a detailed chart view (chart and table)
        // per user selection
        
        let detailedView = WalkingSpeedViewController()
        detailedView.dataValues = originalData
        WalkingSpeedViewController.displayTimeline =
            indexPath.row == 0 ? .daily :
            indexPath.row == 1 ? .weekly : .monthly
        self.present(detailedView, animated: true, completion: nil)
    }
}
