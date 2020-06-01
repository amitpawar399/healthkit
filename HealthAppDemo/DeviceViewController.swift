//
//  DeviceViewController.swift
//  HealthAppDemo
//
//  Created by Amit Pawar on 23/05/20.
//  Copyright © 2020 Amit Pawar. All rights reserved.
//

import UIKit
import HealthKit

class DeviceViewController: UIViewController {
    
    @IBOutlet weak var deviceTableView: UITableView!
    @IBOutlet weak var setpCountLabel: UILabel!
    let healthkitStore = HKHealthStore()
    var hkSourceList = [HKSource]()
    override func viewDidLoad() {
        super.viewDidLoad()
      
        DispatchQueue.main.async {
        
               self.getHealthKitPermission()
        }
        getTodaysSteps { (stepsCount) in
            DispatchQueue.main.async {
            self.setpCountLabel.text = "Today's step count: \(Int(stepsCount))"
            }
        }
        deviceTableView.delegate = self
        deviceTableView.dataSource = self
        
//        getDeviceList { hkSources in
//            self.hkSourceList = hkSources
//            print(hkSources)
//             DispatchQueue.main.async {
//            self.deviceTableView.reloadData()
//            }
//        }
        getDeviceListBySampleAPI()
    }
    
    func getHealthKitPermission() {
        
        
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        guard let stepsCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else { return }
        self.healthkitStore.requestAuthorization(toShare: [], read: [stepsCountType]) { (success, error) in
            if success {
                print("Permission accept.")
            }
        }
    }
    func goToSettings() {
        let alert = UIAlertController(title: "Alert", message: "HealthKit access disabled, Please enable it in settings", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: { action in
                                               
            guard
                let settingsURL = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(settingsURL)
                else { return
            }
            
            UIApplication.shared.open(settingsURL)
            // updocuemnted
            //    UIApplication.shared.open(URL(string: "x-apple-health://")!)
        })
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)

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
            print(sum.doubleValue(for: HKUnit.count()))
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthkitStore.execute(query)
    }
    func getDeviceList(completion: @escaping ([HKSource]) -> Void) {
        var hkSourceList = [HKSource]()
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let query = HKSourceQuery.init(sampleType: stepCountType,
                                       samplePredicate: nil) { (query, sources, error) in
                                        for source in sources! {
    
                                            hkSourceList.append(source)
                                        }
                                        print(sources)
                                completion(hkSourceList)
        }
        healthkitStore.execute(query)
    }
    func getDeviceListBySampleAPI() {
        let nows = Date()
        let now = Calendar.current.date(byAdding: .day, value: -10, to: nows)!
         let startOfDay = Calendar.current.date(byAdding: .day, value: -10, to: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let query = HKSampleQuery.init(sampleType: sampleType!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error)  in
            if let results = results as? [HKQuantitySample] {
                for result in results {
                    
                //    if let device = result.device,let model = device.model, model.contains("Watch") {
                    let source = result.sourceRevision.source
                        // model -->  iPhone  /  Watch
                              self.hkSourceList.append(source)
                    }

               // }
                DispatchQueue.main.async {
                    self.deviceTableView.reloadData()
                }
            }
        }
        self.healthkitStore.execute(query)
    }
}
extension DeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let device = hkSourceList[indexPath.row]
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "StepsDetailsViewController") as? StepsDetailsViewController
        vc?.hKSource = device
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}

extension DeviceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = hkSourceList[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = device.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hkSourceList.count
    }
}
