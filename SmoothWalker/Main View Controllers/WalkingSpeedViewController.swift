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
        // Caller has setup dataValues and displayTimeline
        // Noew show the chart and detailed table
        //
        self.reloadData()
    }
    
    //
    // change the diesplay timeline as per user
    //
    private func changeTimeline(_ timeline : Timeline)
    {
        if WalkingSpeedViewController.displayTimeline != timeline
        {
            WalkingSpeedViewController.displayTimeline = timeline
            self.reloadData()
        }
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
            maxY =  maxY < 1.0 ? 1.5 :  round(maxY + 0.8)
            
            self.chartView.graphView.yMinimum = 0
            self.chartView.graphView.yMaximum = CGFloat(maxY)
            
            if let dateLastUpdated = self.dateLastUpdated {
                self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            }
        }
    }
}
