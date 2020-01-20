//
//  Archiving.swift
//  IOS-Memory-Storage
//
//  Created by michsien on 20/01/2020.
//  Copyright © 2020 Michał Sieńczak. All rights reserved.
//

import Foundation

class Archiving {
    let sensorsPath = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("sensors")
    let readingsPath = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("readings")
    
    func generateData() -> TimeInterval {
        let start = Date()
        
        let (sensors, readings) = generateSensorsAndReadings()
        do {
            try saveDataToFile(sensors: sensors, readings: readings)
        } catch let err {
            print("Saving archiving data failed! " + err.localizedDescription)
        }
        
        let end = Date()
        let time = end.timeIntervalSince(start)
        return time
    }
    
    func generateSensorsAndReadings() -> ([Sensor], [Reading]) {
        var sensors: [Sensor] = []
        var readings: [Reading] = []
        
        for i in 1...Utils.SensorsCount {
            let name = i < 10 ? String(format: "S0%d", i) : String(format: "S%d", i)
            let id = i
            let description = String(format: "Sensor number %d", i)
            sensors.append(Sensor(id: id, name: name , descriptions: description))
        }
        
        for _ in 1...Utils.ReadingsCount {
            let timestamp = Utils.generateRandTimestamp()
            let value: Double = Double.random(in: 0.00...100.00)
            let sensorId: Int = Int.random(in: 0...Utils.SensorsCount)
            let reading: Reading = Reading(timestamp: timestamp, value: value, sensorId: sensorId)
            readings.append(reading)
        }
        
//        print("Readings and sensors data structure generated.")
        
        return (sensors, readings)
    }
    
    func saveDataToFile(sensors: [Sensor], readings: [Reading]) throws -> Void {
        if let sensorsUrl = URL(string: sensorsPath.absoluteString) {
            let data = try NSKeyedArchiver.archivedData(withRootObject: sensors, requiringSecureCoding: false)
            try data.write(to: sensorsUrl)
        }
        if let readingsUrl = URL(string: readingsPath.absoluteString) {
            let data = try NSKeyedArchiver.archivedData(withRootObject: readings,requiringSecureCoding: false)
            try data.write(to: readingsUrl)
        }
    }
    
    func readDataFromFile() throws -> ([Sensor], [Reading]) {
        var sensors: [Sensor] = []
        if let sensorsData = NSData(contentsOf: sensorsPath) {
            if let unarchivedSensors = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(Data(referencing:sensorsData)) as? [Sensor] {
                sensors = unarchivedSensors;
            }
        }
        
        var readings: [Reading] = []
        if let readingsData = NSData(contentsOf: readingsPath) {
            if let unarchivedReadings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(Data(referencing:readingsData)) as? [Reading] {
                readings = unarchivedReadings;
            }
        }
        
        return (sensors, readings)
    }
    
    //MARK: Queries
    
    func queryTimestamps() -> (TimeInterval, Int?, Int?) {
        let start = Date()
        
        var min: Int? = nil
        var max: Int? = nil
        do {
            var (_, readings) = try readDataFromFile()
            readings.sort { $0.timestamp < $1.timestamp}
            min = readings.first?.timestamp
            max = readings.last?.timestamp
        } catch let error {
            print("Reading archived data failed! " + error.localizedDescription)
        }
        
        let end = Date()
        let time = end.timeIntervalSince(start)
        return (time, min, max)
    }
    
    func queryAverage() -> (TimeInterval, Double?) {
        let start = Date()
        
        var average: Double? = nil
        do {
            var sum = 0.0
            let (_, readings) = try readDataFromFile()
            readings.forEach { sum += $0.value }
            average = sum / Double(readings.count)
        } catch let error {
            print("Reading archived data failed! " + error.localizedDescription)
        }
        
        let end = Date()
        let time = end.timeIntervalSince(start)
        return (time, average)
    }
    
    func queryAverageGroupedBySensor() -> (TimeInterval, [Int: Double]) {
        let start = Date()
        
        var averages: [Int: Double] = [:]
        do {
            let (sensors, readings) = try readDataFromFile()
            
            sensors.forEach { (sensor) in
                let sensorReadings = readings.filter { $0.sensorId == sensor.id}
                
                var sum: Double = 0.0
                sensorReadings.forEach { sum += $0.value }
                let averageForSensor = sum / Double(sensorReadings.count)
                averages[sensor.id] = averageForSensor
            }
        } catch let error {
            print("Reading archived data failed! " + error.localizedDescription)
        }
        
        let end = Date()
        let time = end.timeIntervalSince(start)
        return (time, averages)
    }
}

class Sensor: NSObject, NSCoding {
    let id: Int
    let name: String
    let descriptions: String
    
    struct PropertyKey {
        static let id = "id"
        static let name = "name"
        static let descriptions = "descriptions"
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: PropertyKey.id)
        coder.encode(name, forKey: PropertyKey.name)
        coder.encode(descriptions, forKey: PropertyKey.descriptions)
    }
    
    required convenience init?(coder: NSCoder) {
        let id = coder.decodeInteger(forKey: PropertyKey.id)
        guard let name = coder.decodeObject(forKey: PropertyKey.name) as? String else {
            print("Decoding sensor name error!")
            return nil
        }
        guard let descriptions = coder.decodeObject(forKey: PropertyKey.descriptions) as? String else {
            print("Decoding sensor descriptions error!")
            return nil
        }
        self.init(id: id, name: name, descriptions: descriptions)
    }
    
    init(id: Int, name: String, descriptions: String) {
        self.id = id
        self.name = name
        self.descriptions = descriptions
    }
}

class Reading: NSObject, NSCoding {
    var timestamp: Int
    var value: Double
    var sensorId: Int
    
    struct PropertyKey {
        static let timestamp = "timestamp"
        static let value = "value"
        static let sensorId = "sensorId"
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(timestamp, forKey: PropertyKey.timestamp)
        coder.encode(value, forKey: PropertyKey.value)
        coder.encode(sensorId, forKey: PropertyKey.sensorId)
    }
    
    required convenience init?(coder: NSCoder) {
        let timestamp = coder.decodeInteger(forKey: PropertyKey.timestamp)
        let value = coder.decodeDouble(forKey: PropertyKey.value)
        let sensorId = coder.decodeInteger(forKey: PropertyKey.sensorId)
        self.init(timestamp: timestamp, value: value, sensorId: sensorId)
    }
    
    init(timestamp: Int, value: Double, sensorId: Int) {
        self.timestamp = timestamp
        self.value = value
        self.sensorId = sensorId
    }
}
