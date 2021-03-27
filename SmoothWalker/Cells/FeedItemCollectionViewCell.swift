/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view cell that displays a chart.
*/

import UIKit
import CareKitUI

class DataTypeCollectionViewCell: UICollectionViewCell {
        
    var dataTypeIdentifier: String!
    var statisticalValues: [Double] = []
    
    var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        return chartView
    }()
    
    init(dataTypeIdentifier: String) {
        self.dataTypeIdentifier = dataTypeIdentifier
        
        super.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpView() {
        contentView.addSubview(chartView)
        
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += createChartViewConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func createChartViewConstraints() -> [NSLayoutConstraint] {
        let leading = chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let top = chartView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let trailing = chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let bottom = chartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        
        trailing.priority -= 1
        bottom.priority -= 1

        return [leading, top, trailing, bottom]
    }
    
    func getChartHeader(_ row : Int) -> String {
        switch (row) {
        case 0: return "Daily Average Walking Speed"
        case 1: return "Weekly Average Walking Speed"
        default: return "Monthly Average Walking Speed"
        }
    }
    
    func updateChartView(with dataTypeIdentifier: String, values: [Double], labels: [String], timeStamp : String?, row : Int) {
        self.dataTypeIdentifier = dataTypeIdentifier
        self.statisticalValues = values
        
        // Update headerView
        chartView.headerView.titleLabel.text = !labels.isEmpty ?
            getChartHeader(row) :
            getDataTypeName(for: dataTypeIdentifier) ?? "Data"
        chartView.headerView.detailLabel.text =
            timeStamp ?? createChartWeeklyDateRangeLabel()
        
        // Update graphView
        chartView.applyDefaultConfiguration()
        
        chartView.graphView.horizontalAxisMarkers = labels.isEmpty ? createHorizontalAxisMarkers() : labels
        
       
        // Update graphView dataSeries
        let dataPoints: [CGFloat] = statisticalValues.map { CGFloat($0) }
        
        guard
            let unit = preferredUnit(for: dataTypeIdentifier),
            let unitTitle = getUnitDescription(for: unit)
        else {
            return
        }
         
        chartView.graphView.dataSeries = [
            OCKDataSeries(values: dataPoints, title: unitTitle)
        ]
        
        DispatchQueue.main.async {
            var maxY = 0.0
            values.forEach { maxY = max(maxY,$0) }
            maxY =  maxY < 1.0 ? 1.5 : round(maxY + 0.8)
        
            self.chartView.graphView.yMinimum = 0
            self.chartView.graphView.yMaximum = CGFloat(maxY)
        }
    }
}
