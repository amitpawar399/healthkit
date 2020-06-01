//
//  ViewController.swift
//  HealthAppDemo
//
//  Created by Amit Pawar on 21/05/20.
//  Copyright © 2020 Amit Pawar. All rights reserved.
//

import UIKit
import HealthKit
class ViewController: UIViewController {
  let healthkitStore = HKHealthStore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getHealthKitPermission()
    }

    func getHealthKitPermission() {
        
        
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        self.healthkitStore.requestAuthorization(toShare: [], read: [stepsCount]) { (success, error) in
            if success {
                print("Permission accept.")
                print(stepsCount)
            }
            else {
                if error != nil {
                    print(error ?? "")
                }
                print("Permission denied.")
            }
        }
        getTodaysSteps { (stepsCount) in
             print(stepsCount)
        }
     //   testSampleQuery()
        testsssSourceQuery()
      //  testsssSourceQuery()
       // ddfssss()
    }

    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthkitStore.execute(query)
    }
    func testStatisticsCollectionQueryCumulitive() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
                let calendar = Calendar.current
        //start of month

        //...
        
        
        var interval = DateComponents()
        interval.hour = 4
        
       // let calendar = Calendar.current
 
        
        
        let currentDate = Date()
        let CurrentTimeZone = NSTimeZone(abbreviation: "GMT")
        let SystemTimeZone = NSTimeZone.system as NSTimeZone
        let currentGMTOffset: Int? = CurrentTimeZone?.secondsFromGMT(for: currentDate)
        let SystemGMTOffset: Int = SystemTimeZone.secondsFromGMT(for: currentDate)
        let intervals = TimeInterval((SystemGMTOffset - currentGMTOffset!))
        let todayDate = Date(timeInterval: intervals, since: currentDate)
        print("Current time zone Today Date : \(todayDate)")
        let newDate = calendar.date(byAdding: .day, value: -4, to: todayDate)
      //  print(newDate)
//        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: todayDate)
//        print(anchorDate)
        
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: [.cumulativeSum, .separateBySource],
                                                     anchorDate: todayDate,
                                                     intervalComponents: interval)
        
        query.initialResultsHandler = {
            query, results, error in
            
            let startDate = calendar.startOfDay(for: Date())
            
            print("Cumulative Sum")
            results?.enumerateStatistics(from: startDate,
                                         to: Date(), with: { (result, stop) in
                                            print("Time: \(result.startDate), \(result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)")
                                       
            })
            
            print("By Source")
            
            for source in (results?.sources())! {
                //print("Next Device: \(source.name)--\(source.bundleIdentifier)")
                results?.enumerateStatistics(from: newDate!,
                                             to: todayDate, with: { (result, stop) in
//                                                print("\(result.startDate): \(result.sumQuantity(for: source)?.doubleValue(for: HKUnit.count()) ?? 0)")
                                                let fff = HKQuery.predicateForObjects(from: source)
                                                print(fff)
                                                print("Next Device: \(source.name)---\(source.bundleIdentifier)--\(result.sumQuantity(for: source)?.doubleValue(for: HKUnit.count()) ?? 0)")
                                       
                })
            }
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in
            print(query)
            print(statistics)
            print(statisticsCollection)
            print(error)
        }
        
        healthkitStore.execute(query)
    }
    // HKSampleQuery with a nil predicate
    func testSampleQuery() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        
       print("-start-->\(now)")
        print("-end-->\(startOfDay)")
        // Simple Step count query with no predicate and no sort descriptors
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        var count = 0
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: predicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
                                        if let results = results as? [HKQuantitySample] {
                                            for result in results {
                                           
                                                         count = count + result.count
                                        

                                            }
                                        }
                                        print("--->\(count)")
                                        
        }
        var dataDic = [String: String]()
        let quersy = HKSampleQuery.init(sampleType: sampleType!, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error)  in
            if let results = results as? [HKQuantitySample] {
                for result in results {
                    
                    print("-->\(result.device)")
                    
              
                        dataDic[result.sourceRevision.source.bundleIdentifier] = result.sourceRevision.source.name
                  
                }
            }
            print("---->>>\(dataDic.count)")
        }
        
        healthkitStore.execute(quersy)
    }
    func testsssSourceQuery() {
    var dataDic = [String: String]()
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the body mass type ***")
        }
        
        let query = HKSourceQuery.init(sampleType: bodyMassType,
                                       samplePredicate: nil) { (query, sources, error) in
                                        for source in sources! {
                                                   dataDic[source.bundleIdentifier] = source.name
                                        }
                                        print("---->>>\(dataDic.count)")
        }
        
        healthkitStore.execute(query)
    }

}


