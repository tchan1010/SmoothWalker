//
//  WalkingSpeedViewController.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit

class WalkingSpeedViewController: HealthQueryTableViewController {
    
    /// The date from the latest server response.
    private var dateLastUpdated: Date?
    private var originalData  = [HealthDataTypeValue]()
    
    /*------------------------------------------------------------------*/
   
    /// MARK:  Handle different display timelines as selected by user
    
    static var displayTimeline = Timeline.daily
    
    // MARK: Initializers
    
    init() {
        super.init(dataTypeIdentifier: HKQuantityTypeIdentifier.walkingSpeed.rawValue)
        
        // Set weekly predicate
        queryPredicate = createLastWeekPredicate()
    
        // add the Show button
        let barButtonItem = UIBarButtonItem(title: "Show", style: .plain, target: self, action: #selector(didTapShowButton))
            
        navigationItem.leftBarButtonItem = barButtonItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear: dataValues: \(dataValues.count)")
            
        // Authorization
        if !dataValues.isEmpty { return }
        
        WalkingSpeedViewController.displayTimeline =  restoreUserSelectedTimeline()
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [dataTypeIdentifier]) { (success) in
            if success {
                print("request HS access successful. originalDate: \(self.originalData.count)...")
                
                if !self.originalData.isEmpty {
                    self.originalData = []
                    // Perform the query and reload the data.
                    self.loadData()
                }
            }
            else {
                print("request HS access failed...")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        WalkingSpeedViewController.displayTimeline = .daily
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
        
        guard !originalData.isEmpty else {
            showMsg(self,"Walking speed data unavailable. Did you click the Fetch button to load data?")
            return
        }
        
        let vc = UIAlertController(title: "SmoothWalker", message: "Select a Display Option", preferredStyle: .actionSheet)
        
        for caseItem in Timeline.allCases {
            vc.addAction(
                UIAlertAction(title: caseItem.rawValue, style: .default, handler: { action in
                
                self.changeTimeline(caseItem)
            }))
           
        }
        
        vc.addAction(
            UIAlertAction(title: "All Charts", style: .default, handler: {
                action in
                let chartVC = WalkingSpeedChartsViewController()
                chartVC.originalData = self.originalData
                self.present(chartVC, animated: true, completion: nil)
            })
        )
        
        vc.addAction( UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc
    override func didTapFetchButton() {
        
        guard originalData.isEmpty else {
            
            showMsg(self,"You have already fetched data")
            return
        }

        
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
            else if let error = error {
                DispatchQueue.main.async {
                    showMsg(self,"Access health store failed. Error: \(error.localizedDescription).\nIf you have previously denied the app's access to the Walking Speed category, please authorize the app (read and write) access to that category in the Health app; otherwise please visit the Welcome page and request authorization of all categories, including the Walking Speed")
                }
            }
        }
    }
    
    private func setupDataValuesForTimeline() {
        
        switch (WalkingSpeedViewController.displayTimeline) {
        case .daily:
            dataValues = originalData
        case .weekly:
            dataValues = xlateWeeklyDataValues(originalData)
            break
        case .monthly:
            dataValues = xlateMonthlyDataValues(originalData)
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
            maxY =  maxY < 1.0 ? 1.0 :  round(maxY + 0.8)
            
            self.chartView.graphView.yMinimum = 0
            self.chartView.graphView.yMaximum = CGFloat(maxY)
            
            if let dateLastUpdated = self.dateLastUpdated {
                self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            }
        }
    }

}
