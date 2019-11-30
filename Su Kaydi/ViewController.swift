//
//  ViewController.swift
//  Su Kaydi
//
//  Created by Ege Sucu on 30.11.2019.
//  Copyright © 2019 Softhion. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    var store : HKHealthStore?
    
    //    MARK: IBOutlet Variables
    @IBOutlet weak var waterLabel: UILabel!
    @IBOutlet weak var refreshbutton: UIBarButtonItem!
    @IBOutlet weak var writeDataButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        checkHealthKit()
        store = HKHealthStore()
        
        
    }

    
    private func checkHealthKit(){
        
        if HKHealthStore.isHealthDataAvailable(){ // Kullanıcının cihazı destekliyor.
            store = HKHealthStore()
            
            let dataTypes = Set([HKObjectType.quantityType(forIdentifier: .dietaryWater)!])
            
            store?.requestAuthorization(toShare: dataTypes, read: dataTypes, completion: { (_, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    //                    Bağlantı kuruldu. Kullanıcı izin verdi anlamına gelmez!
                }
            })
            
        } else { //kullanıcı iPad gibi desteklenmeyen bir cihaz kullanıyor.
            store = nil
            
            refreshbutton.isEnabled = false
            writeDataButton.isEnabled = false
            
            print("HealthKit is not supported on this device.")
        }
        
    }
    
    private func readData(){
        
        store = HKHealthStore()
        
        guard let waterType = HKSampleType.quantityType(forIdentifier: .dietaryWater) else {
            print("Data not available")
            return
            
        }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let todayPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: waterType, predicate: todayPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, sample, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let samples = sample as? [HKQuantitySample]{
                let totalWater = samples.reduce(0.0){ $0 + $1.quantity.doubleValue(for: HKUnit.literUnit(with: .milli)) }
                let totalInText = String(format: "%.f", totalWater)
                DispatchQueue.main.async {
                    self.waterLabel.text = "\(totalInText) ml su içtin."
                }
            }
            
        }
        store!.execute(query)
        
    }
    
    private func writeData(amount: Int){
        
        store = HKHealthStore()
        
        guard let waterType = HKSampleType.quantityType(forIdentifier: .dietaryWater) else {
            print("Data not available")
            return
            
        }
        
        let waterQuantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: Double(amount))
        let today = Date()
        let waterQuantitySample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: today, end: today)
        
        store!.save(waterQuantitySample) { (_, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.readData()
            }
        }
        
        
    }
    
    
    @IBAction func saveValuePressed(_ sender: UIButton) {
        var amount = 0
        let alert = UIAlertController(title: "Selam", message: "Ne kadar su içtin?", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "1.000"
            textfield.keyboardType = .numberPad
        }
        
        let addAction = UIAlertAction(title: "Ekle", style: .default) { (action) in
            guard let textfields = alert.textFields,
                let amountText = textfields[0].text else {return}
            amount = Int(amountText) ?? 0
            self.writeData(amount: amount)
            
        }
        let cancelAction = UIAlertAction(title: "İptal Et", style: .cancel, handler: nil)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func reloadDataPressed(_ sender: UIBarButtonItem) {
        
        readData()
        
    }
    
}

