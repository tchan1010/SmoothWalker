/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main tab view controller used in the app.
*/

import UIKit
import HealthKit

/// The tab view controller for the app. The controller will load the last viewed view controller on `viewDidLoad`.
class MainTabViewController: UITabBarController {
    
    // MARK: - Initializers
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        setUpTabViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    func setUpTabViewController() {
        let viewControllers = [
            createWelcomeViewController(),
            createWeeklyQuantitySampleTableViewController(),
            createChartViewController(),
            createWeeklyReportViewController(),
            createWalkingSpeedTableViewController()
        ]
        
        self.viewControllers = viewControllers.map {
            UINavigationController(rootViewController: $0)
        }
        
        delegate = self
        selectedIndex = getLastViewedViewControllerIndex()
    }
    
    private func createWelcomeViewController() -> UIViewController {
        let viewController = WelcomeViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Welcome",
                                                 image: UIImage(systemName:
                                                        "house"),
                                                 selectedImage: UIImage(systemName:
                                                        "house.fill"))
        return viewController
    }
    
    private func createWeeklyQuantitySampleTableViewController() -> UIViewController {
        let dataTypeIdentifier = HKQuantityTypeIdentifier.stepCount.rawValue
        let viewController = WeeklyQuantitySampleTableViewController(dataTypeIdentifier: dataTypeIdentifier)
        
        viewController.tabBarItem = UITabBarItem(title: "Health Data",
                                                 image: UIImage(systemName: "circle.grid.cross"),
                                                 selectedImage: UIImage(systemName: "circle.grid.cross.fill"))
        return viewController
    }
    
    private func createWalkingSpeedTableViewController() -> UIViewController {
        let viewController = WalkingSpeedChartsViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Walking Speed",
                                                 image: UIImage(systemName: "figure.walk"),
                                                 selectedImage: UIImage(systemName: "figure.walk.fill"))
        return viewController
    }
    
    private func createChartViewController() -> UIViewController {
        let viewController = MobilityChartDataViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Charts",
                                                 image: UIImage(systemName: "chart.bar.doc.horizontal"),
                                                 selectedImage: UIImage(systemName: "chart.bar.doc.horizontal.fill"))
        return viewController
    }
    
    private func createWeeklyReportViewController() -> UIViewController {
        let viewController = WeeklyReportTableViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Weekly Report",
                                                 image: UIImage(systemName: "calendar"),
                                                 selectedImage: UIImage(systemName: "calendar.fill"))
        return viewController
    }
    
    // MARK: - View Persistence
    
    private static let lastViewControllerViewed = "LastViewControllerViewed"
    private var userDefaults = UserDefaults.standard
    
    private func getLastViewedViewControllerIndex() -> Int {
        if let index = userDefaults.object(forKey: Self.lastViewControllerViewed) as? Int {
            return index
        }
        
        return 0 // Default to first view controller.
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabViewController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else { return }
        
        setLastViewedViewControllerIndex(index)
    }
    
    private func setLastViewedViewControllerIndex(_ index: Int) {
        userDefaults.set(index, forKey: Self.lastViewControllerViewed)
    }
}
