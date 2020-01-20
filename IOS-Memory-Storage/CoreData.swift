//
//  CoreData.swift
//  IOS-Memory-Storage
//
//  Created by michsien on 20/01/2020.
//  Copyright © 2020 Michał Sieńczak. All rights reserved.
//

import Foundation
import CoreData

class CoreData {
    private let context: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.context = managedObjectContext
    }
    
    func generateData() {
        
        var sensors: [SensorsCore] = []
        var readings: [ReadingsCore] = []
        
        for i in 1...Utils.SensorsCount {
            let name = i < 10 ? String(format: "S0%d", i) : String(format: "S%d", i)
            let description = String(format: "Sensor number %d", i)
            let newSensor = SensorsCore(context: context)
            newSensor.name = name
            newSensor.descriptions = description
            sensors.append(newSensor)
        }
        
        for _ in 1...Utils.ReadingsCount {
            let timestamp = Utils.generateRandomDate(daysBack: 365)
            let value: Double = Double.random(in: 0.00...100.00)
            let newReading = ReadingsCore(context: context)
            newReading.timestamp = timestamp
            newReading.value = value
            newReading.sensor = sensors[Int.random(in: 0...Utils.SensorsCount-1)]
            readings.append(newReading)
        }
    
        saveData()
    }
    
    func saveData() {
        do {
            try context.save()
        } catch let e as NSError {
            print ("Saving data error" + e.localizedDescription)
        }
    }
    
    func resetData() {
        if let data = readDataFromContext() {
            data.0.forEach( {context.delete($0)})
            data.1.forEach( {context.delete($0)})
        } else {
            print("Error while deleting fetched data")
        }
        saveData();
    }
    
    func readDataFromContext() -> ([SensorsCore], [ReadingsCore])? {
        let fetchSensorRequest: NSFetchRequest<SensorsCore> = SensorsCore.fetchRequest()
        let fetchReadingRequest: NSFetchRequest<ReadingsCore> = ReadingsCore.fetchRequest()
        
        do {
            let sensors = try context.fetch(fetchSensorRequest)
            let readings = try context.fetch(fetchReadingRequest)
            return (sensors, readings)
        } catch let e as NSError {
            print("Error fetching data from CoreData" + e.localizedDescription);
            return nil
        }
    }
    
    func coreMinMax() -> (TimeInterval, (Date?, Date?)?) {
        let startTime = NSDate()
        
        let minTimestamp = NSExpressionDescription()
        minTimestamp.expressionResultType = .integer32AttributeType
        minTimestamp.name = "min date"
        minTimestamp.expression = NSExpression(format: "@min.timestamp")
        
        let maxTimestamp = NSExpressionDescription()
        maxTimestamp.expressionResultType = .integer32AttributeType
        maxTimestamp.name = "max date"
        maxTimestamp.expression = NSExpression(format: "@max.timestamp")
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReadingsCore")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = [minTimestamp, maxTimestamp]
        
        var minMax: (Date?, Date?)? = nil
        do {
            let result = try context.fetch(fetchRequest)
            if let result = result[0] as? [String: Double] {
                minMax = (Date(timeIntervalSinceReferenceDate: result["min date"]!), Date(timeIntervalSinceReferenceDate: result["max date"]!))
            }
        } catch let e as NSError {
            print("Error getting data from query!" + e.localizedDescription)
        }
        
        let finishTime = NSDate()
        let measuredTime = finishTime.timeIntervalSince(startTime as Date);
        print("CoreData minmax query finished in \(measuredTime)")
        return (measuredTime, minMax)
    }
    
    func coreAverage() -> (TimeInterval, Double?) {
        let startTime = NSDate()
        
        let key = NSExpression(forKeyPath: "value")
        let average = NSExpressionDescription()
        average.expressionResultType = .doubleAttributeType
        average.name = "avg value"
        average.expression = NSExpression(forFunction: "average:", arguments: [key])
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReadingsCore")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = [average]
        
        var avg: Double? = nil
        do {
            let result = try context.fetch(fetchRequest)
            if let dict = result[0] as? [String: Double] {
                avg = dict["avg value"]
            }
        } catch let e as NSError {
            print("Unable to fetch data! " + e.localizedDescription)
        }
        
        let finishTime = NSDate()
        let measuredTime = finishTime.timeIntervalSince(startTime as Date)
        
        print("CoreData avg query finished in \(measuredTime)")
        return (measuredTime, avg)
    }
    
    func coreAverageGroupedBySensor() -> (TimeInterval, [String:Double]) {
        let startTime = NSDate()
        
        var averagesDict: [String:Double] = [:]
        
        let key = NSExpression(forKeyPath: "value")
        let average = NSExpressionDescription()
        average.expressionResultType = .doubleAttributeType
        average.name = "avg value"
        average.expression = NSExpression(forFunction: "average:", arguments: [key])
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReadingsCore")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.propertiesToGroupBy = ["sensor.name"]
        fetchRequest.propertiesToFetch = ["sensor.name", average]
        
        do {
            if let results = try context.fetch(fetchRequest) as? [NSDictionary] {
                for result in results {
                    if let sensor = result["sensor.name"] as? String,
                        let avg = result["avg value"] as? Double {
                        averagesDict[sensor] = avg
                    }
                }
            }
        } catch let e as NSError {
            print("Error geting data" + e.localizedDescription)
        }
        
        
        let finishTime = NSDate()
        let measuredTime = finishTime.timeIntervalSince(startTime as Date)
        
        return (measuredTime, averagesDict)
    }
}
