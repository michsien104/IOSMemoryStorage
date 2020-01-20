//
//  ViewController.swift
//  IOS-Memory-Storage
//
//  Created by michsien on 20/01/2020.
//  Copyright © 2020 Michał Sieńczak. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let archiving = Archiving()
    let sqlite = SQLite()
    let core = CoreData(managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func resetButton(_ sender: Any) {
        textView.text = ""
    }
    
    private func log(_ message: String) {
        textView.text += "\n" + message
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func generateArchiving(_ sender: Any) {
        let time = archiving.generateData()
        log(String(format: "Archiving data generated in %.5f s", time))
    }
    
    //Archiving
    @IBAction func testArchiving(_ sender: Any) {
        let (time, min, max) = archiving.queryTimestamps()
        log(String(format: "Calculated min = %d, max = %d in %.5f s", min ?? -1, max ?? -1, time))
        
        let (time2, average) = archiving.queryAverage()
        log(String(format: "Calculated average = %f in %.5f s", average ?? -1.0, time2))
        
        let (time3, averagesForSensors) = archiving.queryAverageGroupedBySensor()
        log(String(format: "Calculated average for each sensor in %.5f s", time3))
        averagesForSensors.forEach { (key, value) in
            log(" Average for sensor \(key) is \(value)")
        }
    }
    
    //SQLite
    @IBAction func generateSQLite(_ sender: Any) {
        let time = sqlite.generateData()
        log(String(format: "SQLite data generated in %.5f s", time))
    }
    
    @IBAction func testSQLite(_ sender: Any) {
        let (timeMin, timeMax, min, max) = sqlite.queryTimestamps()
        
        log(String(format: "SQLite query min = \(String(describing: min)) in %.5f s",timeMin))
        log(String(format: "SQLite query max = \(String(describing: max)) in %.5f s",timeMax))
        
        let (time, average) = sqlite.queryAverage()
        log(String(format: "SQLite query avg = \(average ?? -1.0) in %.5f s",time))
        
        let (time3, averagesForSensors) = sqlite.queryAverageGroupedBySensor()
        log(String(format: "Calculated average for each sensor in %.5f s", time3))
        averagesForSensors.forEach { (key, value) in
            log(" Average for sensor \(key) is \(value)")
        }
    }
    
    //Core
    @IBAction func generateCoreData(_ sender: Any) {
        let startTime = NSDate()
        
        core.resetData()
        core.generateData()
        core.saveData();
        
        let finishTime = NSDate()
        let measuredTime = finishTime.timeIntervalSince(startTime as Date)
//        print("CoreData generate finished in \(measuredTime)")
        log(String(format: "CoreData data generated in %.5f s", measuredTime))
    }
    
    @IBAction func testCoreData(_ sender: Any) {
        
        let (time, minMax) = core.coreMinMax()
        log(String(format: "CoreData min max queried in %.5f s", time))
        log(String(format: "CoreData query min = \(String(describing: minMax?.0))"))
        log(String(format: "CoreData query max = \(String(describing: minMax?.1))"))
        
        let (time2, avg) = core.coreAverage()
        log(String(format: "CoreData min max queried in %.5f s", time2))
        log(String(format: "CoreData average reading value: \(String(describing: avg))"))
        
        let (time3, averagesForSensors) = core.coreAverageGroupedBySensor()
        log(String(format: "Calculated average for each sensor in %.5f s", time3))
        averagesForSensors.forEach { (key, value) in
            log(" Average for sensor \(key) is \(value)")
        }
    }
}

