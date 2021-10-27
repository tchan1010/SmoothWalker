/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays a chart and table view with health data samples.
*/

import UIKit
import HealthKit

class WeeklyReportTableViewController: HealthQueryTableViewController {
    
    /// The date from the latest server response.
    private var dateLastUpdated: Date?
    
    // MARK: Initializers
    
    init() {
        super.init(dataTypeIdentifier:
                    HKQuantityTypeIdentifier.walkingSpeed.rawValue /*
                   HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue*/)
        
        // Set weekly predicate
        queryPredicate = createLastWeekPredicate()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let btn = navigationItem.rightBarButtonItem  {
            btn.isEnabled = false
            btn.title = ""
        }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [dataTypeIdentifier]) { (success) in
            if success {
                // Perform the query and reload the data.
                self.loadData()
            }
        }
    }
    
    // MARK: - Selector Overrides
    
    @objc
    override func didTapFetchButton() {
        /* Don't use mocked server data
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from: serverResponse.date)
            self?.handleServerResponse(serverResponse)
        }
         */
    }
    
    
    // MARK: - Network
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    /*
    override func handleServerResponse(_ serverResponse: ServerResponse) {
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
            let quantity = HKQuantity(unit: .meter(), doubleValue: serverHealthSample.value)
            let sampleType = HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!
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
                print("Save to Health store failed: \(error.localizedDescription)")
            }
        }
    }
    */
    

    override func loadData() {
        
        self.dataValues = []
        
        performQuery {
            
            if !self.dataValues.isEmpty {
                
                DispatchQueue.main.async { [weak self] in
                    self?.reloadData()
                }
            }
            else {
                // Failure: No data. Tell users and show the Fetch button
                print("No Data")
            }
            
        }
    }

    //
    // Query data from Health store
    override func performQuery(completion: @escaping () -> Void) {
        
        guard let sampleType = getSampleType(for: dataTypeIdentifier) else { return }
        
        let anchoredObjectQuery = HKAnchoredObjectQuery(type: sampleType,
                                predicate: queryPredicate,
                                anchor: queryAnchor,
                                limit: queryLimit) {
            (query, samplesOrNil, deletedObjectsOrNil, anchor, errorOrNil) in
            
            guard let samples = samplesOrNil else { return }
            
            self.dataValues = samples.map { (sample) -> HealthDataTypeValue in
                var dataValue = HealthDataTypeValue(
                    startDate: simpleDate(sample.startDate),
                    endDate: simpleDate(sample.endDate),
                    value: .zero)
                if let quantitySample = sample as? HKQuantitySample,
                   let unit = preferredUnit(for: quantitySample) {
                    dataValue.value = quantitySample.quantity.doubleValue(for: unit)
                }
                
                return dataValue
            }
            
            compactDataValues(&self.dataValues,&self.dateLastUpdated)
            
            completion()
        }
        
        HealthData.healthStore.execute(anchoredObjectQuery)
    }


    // MARK: Function Overrides
    
    override func reloadData() {
        super.reloadData()
        
        // Change axis to use weekdays for six-minute walk sample
        DispatchQueue.main.async {
            self.chartView.graphView.horizontalAxisMarkers = createHorizontalAxisMarkers()
            
            if let dateLastUpdated = self.dateLastUpdated {
                self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            }
        }
    }
}
