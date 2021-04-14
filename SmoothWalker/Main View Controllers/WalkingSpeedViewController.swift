//
//  WalkingSpeedViewController.swift
//  SmoothWalker
//
//  Created by Terence Chan on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit

//
// Class to display a detailed chart for daily, weekly or monthly
// average walking speed. This class is instantiated by the
// WalkingSpeedChartsViewController class
//

class WalkingSpeedViewController: HealthQueryTableViewController {
    
    /// The date from the latest server response.
    private var dateLastUpdated: Date?
    private var originalData  = [HealthDataTypeValue]()
    //private var timeStamp : String?
    
    /// MARK:  Handle different display timelines as selected by user
    static var displayTimeline = Timeline.daily
    
    // MARK: Initializers
    
    init() {
        super.init(dataTypeIdentifier: HKQuantityTypeIdentifier.walkingSpeed.rawValue)
        
        //
        // allow user to exit this view via tapping on the view
        //
        let tap = UITapGestureRecognizer(target: self, action: #selector(exitView))
        self.view.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the superclass Fetch button
        if let fetchButton = navigationItem.rightBarButtonItem {
            fetchButton.title = ""
        }
        
        guard !self.dataValues.isEmpty else {
            return
        }
     
        //
        // Caller has setup the dataValues and displayTimeline
        // Just show the chart and table
        //
        self.reloadData()
    }
    
    //
    // MARK: - Buttons action
    //
    
    // Go back to the parent view
    //
    @objc
    func exitView() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // // Dummy out the superclass function
    @objc
    override func didTapFetchButton() {

    }
    
    //
    // Xlate data for the provided timeline
    //
    private func setupDataValuesForTimeline() {
        
        switch (WalkingSpeedViewController.displayTimeline) {
        case .daily:
            var lastSevenDays = [HealthDataTypeValue]()
            for i in (originalData.count-7)..<originalData.count {
                lastSevenDays.append(originalData[i])
            }
            dataValues = lastSevenDays
        case .weekly:
            dataValues = xlateWeeklyDataValues(originalData)
            break
        case .monthly:
            dataValues = xlateMonthlyDataValues(originalData)
            break;
        }
        //timeStamp = getChartTimeStamp(dataValues)
    }
    
    // MARK: Function Overrides
    
    override func reloadData() {
        
        if (originalData.isEmpty) {
            originalData = dataValues
        }
        
        setupDataValuesForTimeline()
       
        // super class will show the chart and table
        //
        super.reloadData()
        
        DispatchQueue.main.async {
            
            // Enable display of fractional digits on Y-axis
            self.chartView.graphView.numberFormatter.maximumFractionDigits = 2
            
            // Compute and set the Y-axis maximum value
            let maxY = self.dataValues.reduce(0.0, { max($0, $1.value) })
            self.chartView.graphView.yMaximum = computeMaxValue(maxY)
            
            // Set the chart date-range timeStamp
            self.chartView.headerView.detailLabel.text = getChartTimeStamp(self.dataValues) ??
                createChartDateLastUpdatedLabel(self.dateLastUpdated ?? Date())
        }
    }
}
