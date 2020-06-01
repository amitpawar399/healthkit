//
//  StepsDetailsViewController.swift
//  HealthAppDemo
//
//  Created by Amit Pawar on 23/05/20.
//  Copyright © 2020 Amit Pawar. All rights reserved.
//

import UIKit
import HealthKit

class StepsDetailsViewController: UIViewController {
    
    let healthkitStore = HKHealthStore()
    @IBOutlet weak var deviceInfoLabel: UILabel!
    
    @IBOutlet weak var todaysStepsLabel: UILabel!
    
    @IBOutlet weak var thisMonthStepsLabe: UILabel!
    var hKSource: HKSource!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceInfoLabel.text = "Device Name:\n\(hKSource.name) \n\nHealth ID: \(hKSource.bundleIdentifier) "
        getTodaysSteps { steps in
            DispatchQueue.main.async {
                self.todaysStepsLabel.text = "Today's Steps: \(Int(steps))"
            }
        }
        
        loadMonthlySteps()
    }
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            //   print(sum.doubleValue(for: HKUnit.count()))
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthkitStore.execute(query)
    }
    
    func loadMonthlySteps() {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        var calender = Calendar.current
        calender.timeZone = TimeZone(abbreviation: "GMT")!
        let startday = calender.date(byAdding: .day, value: -30, to: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startday, end: now, options: .strictStartDate)
        print(hKSource)
        let predicateNew = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, HKQuery.predicateForObjects(from: hKSource)])
        
        var anchorComponents = calender.dateComponents([.day, .month, .year], from: now)
        anchorComponents.hour = 0
        anchorComponents.minute = 0
        let anchorDate = calender.date(from: anchorComponents)
        var interval = DateComponents()
        interval.hour = 24
        let query = HKStatisticsCollectionQuery.init(quantityType: stepsQuantityType,
                                                     quantitySamplePredicate: predicateNew,
                                                     options: [.cumulativeSum, .separateBySource],
                                                     anchorDate: anchorDate!,
                                                     intervalComponents: interval)
        
        query.initialResultsHandler = {
            query, results, error in
            
            for source in (results?.sources())! {
                results?.enumerateStatistics(from: startday!,
                                             to: now, with: { (result, stop) in
                                                
                                                let stepData = result.sumQuantity(for: source)?.doubleValue(for: HKUnit.count()) ?? 0
                                                print("----\(stepData)--\(result.startDate)--\(result.endDate)")
                                                
                })
            }
        }
        healthkitStore.execute(query)
    }
}
