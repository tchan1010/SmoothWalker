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
    private var timeStamp : String?
    
    /// MARK:  Handle different display timelines as selected by user
    static var displayTimeline = Timeline.daily
    
    // MARK: Initializers
    
    init() {
        super.init(dataTypeIdentifier: HKQuantityTypeIdentifier.walkingSpeed.rawValue)
        
        //
        // allow user to exit this view via tapping on the view
        //
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackButton))
        self.view.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // hide the superclass Fetch button
        if let fetchButton = navigationItem.rightBarButtonItem {
            fetchButton.title = ""
        }
        
        guard !self.dataValues.isEmpty else {
            return
        }
     
        //
        // Caller has setup the dataValues and displayTimeline
        // Show the chart and table
        //
        self.reloadData()
    }
    
    //
    // MARK: - Buttons action
    //
    
    // Return to the parent view
    @objc
    func didTapBackButton() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    override func didTapFetchButton() {
        
        // dummy out the superclass function
    }
    
    //
    // Xlate data for the provided timeline
    //
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
        timeStamp = getChartTimeStamp(dataValues)
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
            
            // Enable display of fractional digits
            self.chartView.graphView.numberFormatter.maximumFractionDigits = 2
            
            // Compute and set the Y-axis maximum
            let maxY = self.dataValues.reduce(0.0, { max($0, $1.value) })
            self.chartView.graphView.yMaximum = computeMaxValue(maxY,0.25)
            
            self.chartView.headerView.detailLabel.text = self.timeStamp ??
                createChartDateLastUpdatedLabel(self.dateLastUpdated ?? Date())
        }
    }
}
