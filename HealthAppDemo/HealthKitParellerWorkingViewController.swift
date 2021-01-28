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
         let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
        
        self.healthkitStore.requestAuthorization(toShare: [], read: [stepsCount, distanceWalkingRunning]) { (success, error) in
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
        
        
        launchParallerMethods()
    }
    
    func launchParallerMethods(){
        DispatchQueue.background(background: {
            self.testStepData()
            self.getEveryDatWalkDistanceTest()
        }, completion:{
            print("Data Process Completed")
        })
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
    func testStepData() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        let calendar = Calendar.current
        var interval = DateComponents()
        interval.hour = 4
        
        let currentDate = Date()
        let CurrentTimeZone = NSTimeZone(abbreviation: "GMT")
        let SystemTimeZone = NSTimeZone.system as NSTimeZone
        let currentGMTOffset: Int? = CurrentTimeZone?.secondsFromGMT(for: currentDate)
        let SystemGMTOffset: Int = SystemTimeZone.secondsFromGMT(for: currentDate)
        let intervals = TimeInterval((SystemGMTOffset - currentGMTOffset!))
        let todayDate = Date(timeInterval: intervals, since: currentDate)
        print("Current time zone Today Date : \(todayDate)")

        print("------>Result stepCount requested \(Date())")
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: [.cumulativeSum, .separateBySource],
                                                     anchorDate: todayDate,
                                                     intervalComponents: interval)
        
        query.initialResultsHandler = {
            query, results, error in
            print("------>Result stepCount arrived \(Date())")
            let startDate = calendar.startOfDay(for: Date())
            
            
            results?.enumerateStatistics(from: startDate,
                                         to: Date(), with: { (result, stop) in
                                            // print("Time: \(result.startDate), \(result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)")
                                            
            })
            
        }
        healthkitStore.execute(query)
    }
    func getEveryDatWalkDistanceTest() {
            guard let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
                fatalError("*** Unable to get the step count type ***")
            }
            let calendar = Calendar.current
            
            var interval = DateComponents()
            interval.hour = 4
            let currentDate = Date()
            let CurrentTimeZone = NSTimeZone(abbreviation: "GMT")
            let SystemTimeZone = NSTimeZone.system as NSTimeZone
            let currentGMTOffset: Int? = CurrentTimeZone?.secondsFromGMT(for: currentDate)
            let SystemGMTOffset: Int = SystemTimeZone.secondsFromGMT(for: currentDate)
            let intervals = TimeInterval((SystemGMTOffset - currentGMTOffset!))
            let todayDate = Date(timeInterval: intervals, since: currentDate)
            print("Current time zone Today Date : \(todayDate)")
            let newDate = calendar.date(byAdding: .day, value: -900, to: todayDate)
            print("------>Result distance requested \(Date())")
            let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: distanceWalkingRunning, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { (query, statistics, error) in
                var value: Double = 0
                print("------>Result distance arrived \(Date())")
                if error != nil {
                    print("something went wrong")
                } else if let quantity = statistics?.sumQuantity() {
                    value = quantity.doubleValue(for: HKUnit.mile())
                }
                print("---->distance \(value)")
            }
            healthkitStore.execute(query)
    }
}


extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}
