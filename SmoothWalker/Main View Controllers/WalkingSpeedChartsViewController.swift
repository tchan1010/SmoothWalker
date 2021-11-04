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
    
    var dataValues = [HealthDataTypeValue]()
    
    var queries = [HKAnchoredObjectQuery]()
    
    var fetchButton : UIBarButtonItem?
    
    private let NO_MOBILITY_DATA = "No walking speed data. If you have denied the app access to the Health store's Walking Speed data, you may authorize the app to have access to that category in the Health app. You may click the Settings button to be transfered to the Settings app, where you can find the Health app."
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        // scale factor to fit all three charts in one screen
        scaleCellHeight = 0.625
        
        super.viewDidLoad()
        
        print("WalkingSpeedChartsView: viewdidLoad...")
        
           /* dataTypeIdentifier, values, labels, timeStamp */
        data = [ (mobilityContent[0], [], [], nil), // daily
                 (mobilityContent[0], [], [], nil), // weekly
                 (mobilityContent[0], [], [], nil)  // monthly
               ]
        
        self.dateLastUpdated = Date()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard originalData.isEmpty else { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [dataTypeIdentifier]) { [weak self] (success) in
            if success {
                
                if !(self?.originalData.isEmpty ?? true) {
                    // Perform the query and reload the data.
                    self?.loadData()
                }
                else {
                    self?.fetchLatestData()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        WalkingSpeedViewController.displayTimeline = .daily
       
        self.originalData = []
    }
    
    private func turnOnOffFetchButton(_ turnOn : Bool) {
        
        DispatchQueue.main.async {
            if turnOn {
                if self.fetchButton == nil {
                    self.fetchButton = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(self.fetchLatestData))
            
                    self.navigationItem.rightBarButtonItem = self.fetchButton!
                }
            }
            else {
                self.fetchButton = nil
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    // MARK: Network
    
    // Fetch lastest average walking speed data from Health store
    @objc
    private func fetchLatestData() {
        
        self.queryPredicate = createLastMonthPredicate(from:Date())
        self.loadData()
    }
    
    // Tell users there is no walking speed data, and advise them to
    // visit Settings/Health app to fix authorization issue
    //
    func showMsgAction( msg : String) {
        let vc = UIAlertController(title: "SmoothWalker", message: msg, preferredStyle: .alert)
        
        vc.addAction( UIAlertAction(title: "OK", style:.cancel, handler: nil))
        
        vc.addAction( UIAlertAction(title: "Settings", style: .default, handler: { action in
            
            self.openSettings()
            
        }))
        self.present(vc, animated:true, completion: nil)
    }
    
    // Direct user to the Settings app, in which they can find the Health app
    private func openSettings() {
        
        if let url = URL(string:UIApplication.openSettingsURLString),
             UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
   
    // MARK: - Data Functions
    
    // Attempt to load walkijng speed data from Health store to the app
    //
    func loadData() {
        
        self.dataValues = []
        self.turnOnOffFetchButton(false)
        
        performQuery {
            if !self.dataValues.isEmpty {
                
                // Success! Got walking speed data
                
                self.originalData = self.dataValues
                
                self.setupChartsData {
                    
                    DispatchQueue.main.async { [weak self] in
                        
                        // Update and display the daily, weekly, monthly charts
                        
                        self?.reloadData()
                    }
                }
            }
            else {
                // Failure: No data. Tell users and show the Fetch button
                
                DispatchQueue.main.async { [weak self] in
                    self?.showMsgAction(msg:self!.NO_MOBILITY_DATA)
                    self?.turnOnOffFetchButton(true)
                }
            }
        }
    }

    //
    // Collect data for daily average walking speed.
    // Caller has verified that originalData contains data
    //
    private func setupDailyDataValues(_ dataItem : inout (dataTypeIdentifier: String, values: [Double], labels: [String], timeStamp : String?) )
    {
        var lastSevenDays : [HealthDataTypeValue]
        if originalData.count > 7 {
            lastSevenDays = [HealthDataTypeValue]()
            for i in (originalData.count-7)..<originalData.count {
                lastSevenDays.append(originalData[i])
            }
        }
        else {
            lastSevenDays = originalData
        }
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
               (
                   lastSevenDays.map{ $0.value },
                 
                   lastSevenDays.map{
                       let (_,month,day) = extractDate($0.startDate)
                       return "\(month)/\(day)" },
                
                   getChartTimeStamp(lastSevenDays)!
               )
     }
    
    //
    // Collect data for weekly average walking speed
    //
    private func setupWeeklyDataValues(_ dataItem : inout (dataTypeIdentifier : String,  values: [Double], labels: [String], timeStamp : String?) )
    {
        let dataValues = xlateWeeklyDataValues(originalData)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
            (
                dataValues.map { $0.value },
                
                dataValues.map{
                    dateFormatter.string(from:$0.startDate) + WEEK_SUFFIX },
                
                getChartTimeStamp(dataValues)!
            )
    }
    
    //
    // Collect data for monthly average walking speed
    //
    private func setupMonthlyDataValues(_ dataItem : inout ( dataTypeIdentifier: String, values : [Double], labels : [String], timeStamp : String?) )
    {
        let dataValues = xlateMonthlyDataValues(originalData)
        
        (dataItem.values,dataItem.labels,dataItem.timeStamp) =
             (
                  dataValues.map{ $0.value },
    
                  dataValues.map{
                      monthTitles[extractDate($0.startDate).month-1]},
    
                  getChartTimeStamp(dataValues)!
             )
    }
    
    func xlateSamples(_ samples : [HKSample] )
    {
        self.dataValues = samples.map { (sample) -> HealthDataTypeValue in
            var data = HealthDataTypeValue(
                startDate: simpleDate(sample.startDate),
                endDate: simpleDate(sample.endDate),
                value: .zero)
            if let quantitySample = sample as? HKQuantitySample,
               let unit = preferredUnit(for: quantitySample) {
                data.value = quantitySample.quantity.doubleValue(for: unit)
            }
            
            return data
        }
        compactDataValues(&self.dataValues,&self.dateLastUpdated)
    }
    
    //
    // Query data from Health store
    //
    func performQuery(completion: @escaping () -> Void) {
        
        guard let sampleType = getSampleType(for: dataTypeIdentifier) else { return }
        
        let anchoredQuery = HKAnchoredObjectQuery(type: sampleType,
                                predicate: queryPredicate,
                                anchor: queryAnchor,
                                limit: queryLimit) {
            (query, samplesOrNil, deletedObjectsOrNil, anchor, errorOrNil) in
            
            guard let samples = samplesOrNil else { return }
            
            self.xlateSamples(samples)
            
            completion()
        }
        
        anchoredQuery.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            guard let samples = samplesOrNil else { return }
           
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            if UIApplication.shared.applicationState == .background {
            
                // The results come back on an anonymous background queue.
                Network.push(addedSamples: samples, deletedSamples: deletedObjectsOrNil)
                
                let center = UNUserNotificationCenter.current()
                center.getNotificationSettings { settings in
                    guard (settings.authorizationStatus == .authorized) ||
                          (settings.authorizationStatus == .provisional) else { return }

                    if settings.alertSetting == .enabled {
                        // Schedule an alert-only notification.
                    } else {
                        // Schedule a notification with a badge and sound.
                        return
                    }
                }
               
                let content = UNMutableNotificationContent()
                content.title = "SmoothWalker"
                content.body = "Background refresh triggered"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)

                // Create the request
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                // add notification request
                UNUserNotificationCenter.current().add(request)
            }
            else {
                
                self.xlateSamples(samples)
                
                self.originalData = self.dataValues
                
                self.setupChartsData {
                    
                    DispatchQueue.main.async { [weak self] in
                        
                        // Update and display the daily, weekly, monthly charts
                        
                        self?.reloadData()
                    }
                }
            }
        }
        
        HealthData.healthStore.execute(anchoredQuery)
    }
    
    // Collect data, labels and time stamp for
    // the daily, weekly and monthly charts
    //
    func setupChartsData( completion : @escaping () -> Void) {
     
        if  !originalData.isEmpty  {
            setupDailyDataValues(&data[0])
            setupWeeklyDataValues(&data[1])
            setupMonthlyDataValues(&data[2])
        }

        completion()
    }
    
    // MARK: handle user selection of chart
    // Show a detailed chart view (chart and table
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        
        guard !originalData.isEmpty else {
            
            self.showMsgAction(msg:NO_MOBILITY_DATA)
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
