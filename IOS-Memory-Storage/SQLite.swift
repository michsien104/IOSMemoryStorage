
//
//  FileS.swift
//  IOS-Memory-Storage
//
//  Created by michsien on 20/01/2020.
//  Copyright © 2020 Michał Sieńczak. All rights reserved.
//

import Foundation

class SQLite {
    
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("SensorDatabase.sqlite");
    var db: OpaquePointer?;
    var stmt: OpaquePointer?;
    
    init() {
        execute(sqlite3_open(fileURL.path, &db))
    }
    
    deinit {
        execute(sqlite3_close(db))
    }
    
    func generateData() -> TimeInterval {
        execute(sqlite3_exec(db, "DROP TABLE IF EXISTS Sensors", nil, nil, nil))
        execute(sqlite3_exec(db, "DROP TABLE IF EXISTS Readings", nil, nil, nil))
        
        //start counting time for inserting data into SQLite3 db
        let startTime = NSDate();
        
        execute(sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Sensors (sensorID INTEGER PRIMARY KEY, name TEXT, description TEXT)", nil, nil, nil))
        execute(sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Readings (readingID INTEGER PRIMARY KEY AUTOINCREMENT, sensorID INTEGER NOT NULL, timestamp DOUBLE, value NUMERIC, FOREIGN KEY (sensorID) REFERENCES Sensors (sensorID))", nil, nil, nil))
        
        for n in 1...Utils.SensorsCount {
            sqlite3_reset(stmt)
            let queryString = "Insert INTO Sensors (name, description, sensorID) VALUES (?,?,?);";
            execute(sqlite3_prepare(db, queryString, -1, &stmt, nil))
            
            let name = "S\(n)"
            print(name)
            sqlite3_bind_text(stmt, 1, name, -1, nil) ;
            
            let description = "Sensor number \n" + String(n);
            sqlite3_bind_text(stmt, 2, description, -1, nil);
            
            sqlite3_bind_int(stmt, 3, Int32(n));
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error inserting sensor: \(errmsg)\n");
            } else {
                print("Insert sensor succesfull\n");
            };
        }
        
        for _ in 1...Utils.ReadingsCount {
            sqlite3_reset(stmt)
            let queryString = "Insert INTO Readings (sensorID , timestamp, value) VALUES (?,?,?);";
            execute(sqlite3_prepare(db, queryString, -1, &stmt, nil))
            
            let sensorID = Int32.random(in: 1...20);
            sqlite3_bind_int(stmt, 1, sensorID);
            
            let timestamp = Utils.generateRandomDate(daysBack: 365)!.timeIntervalSinceReferenceDate
//            print("Timestamp \(Date(timeIntervalSinceReferenceDate: timestamp))")
//            print("Timestamp \(timestamp)")
            sqlite3_bind_double(stmt, 2, timestamp);
            
            let value = Double.random(in: 1...100);
            sqlite3_bind_double(stmt, 3, value);
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error inserting reading: \(errmsg)\n");
            } else {
//                print("Insert reading succesfull\n");
            }
        }
        
        let finishTime = NSDate();
        let measuredTime: Double = finishTime.timeIntervalSince(startTime as Date);
        
        print("Measured time of inserting data into SQLite database: \(measuredTime) seconds");
        return measuredTime
    }
    
    func queryTimestamps() -> (TimeInterval, TimeInterval, Date?, Date?) {
        //BIGGEST TIMESTAMP
        var startTime = NSDate();
        sqlite3_reset(stmt)
        var query = "SELECT timestamp FROM Readings ORDER BY timestamp DESC LIMIT 1";
        execute(sqlite3_prepare(db, query, -1, &stmt, nil))
        
        var max: Date? = nil
        while(sqlite3_step(stmt) == SQLITE_ROW) {
            let d = sqlite3_column_double(stmt, 0)
            print("raw timestamp: " + String(d))
            let timestamp = Date(timeIntervalSinceReferenceDate: d);
            print("Biggest timestamp is \(timestamp)");
            max = timestamp
        }
        
        var finishTime = NSDate();
        let measuredTimeMin: Double = finishTime.timeIntervalSince(startTime as Date);
        print("Measured time of querying bigest timestamp from readings SQLite3 database: \(measuredTimeMin) seconds");
        
        //SMALLEST TIMESTAMP
        startTime = NSDate();
        sqlite3_reset(stmt)
        query = "SELECT timestamp FROM Readings ORDER BY timestamp ASC LIMIT 1";
        execute(sqlite3_prepare(db, query, -1, &stmt, nil))
        
        var min: Date? = nil
        while(sqlite3_step(stmt) == SQLITE_ROW) {
            let timestamp = Date(timeIntervalSinceReferenceDate: sqlite3_column_double(stmt, 0));
            print("Smallest timestamp is \(timestamp)");
            min = timestamp;
        }
        
        finishTime = NSDate();
        let measuredTimeMax = finishTime.timeIntervalSince(startTime as Date);
        print("Measured time of querying smalest timestamp from readings SQLite3 database: \(measuredTimeMax) seconds");
        return (measuredTimeMin, measuredTimeMax, min, max)
    }
    
    func queryAverage() -> (TimeInterval, Double?) {
        //AVERAGE VALUE AMONG ALL
        let startTime = NSDate();
        sqlite3_reset(stmt)
        let query = "SELECT avg(value) FROM Readings";
        execute(sqlite3_prepare(db, query, -1, &stmt, nil))
        
        var average: Double? = nil
        while(sqlite3_step(stmt) == SQLITE_ROW) {
            average = sqlite3_column_double(stmt, 0);
            print("Average value reading is \(average ?? -1.0)");
        }
        
        let finishTime = NSDate();
        let measuredTime = finishTime.timeIntervalSince(startTime as Date);
        print("Measured time of querying average value from readings SQLite3 database: \(measuredTime) seconds");
        
        return (measuredTime, average)
    }
    
    func queryAverageGroupedBySensor() -> (TimeInterval, [String: Double]) {
        let startTime = NSDate();
        sqlite3_reset(stmt)
        let query = "SELECT sensorID, avg(value) FROM Readings GROUP BY sensorID";
        if sqlite3_prepare(db, query, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error preparing select statement(query 4): \(errmsg)\n");
        }
        
        var averages: [String: Double] = [:]
        while(sqlite3_step(stmt) == SQLITE_ROW) {
            let id = sqlite3_column_int(stmt, 0)
//            print("dupa \(name)")
            let avgValue = sqlite3_column_double(stmt, 1);
            averages[String(id)] = avgValue
            print("Average value reading of sensor \(id) is \(avgValue)");
        }
        
        let finishTime = NSDate();
        let measuredTime = finishTime.timeIntervalSince(startTime as Date);
        print("Measured time of querying average value per sensor from readings SQLite3 database: \(measuredTime) seconds");
        
        return (measuredTime, averages)
    }
    
    func execute(_ result: Int32) {
        if (result != SQLITE_OK) {
            print(String(format:"Error executing sqlite.", result))
        }
    }

}
