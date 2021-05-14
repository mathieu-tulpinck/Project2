//
//  MainViewController.swift
//  Project2
//
//  Created by mathieu on 08/05/2021.
//

import UIKit
import CoreData
import Charts

class MainViewController: UIViewController {
    
    var persistentContainer: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<AdministrationRecord>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        getDataAPI()
        
        createChart()
    }
    
    func getDataAPI() {
        let helper = FetchDataHelper()
        helper.fetchDataAPI { (response) in
            switch response {
            case .success(let returnedData):
                guard let recordsArray = returnedData.result["administered"] else { return }
                self.saveDataDB(data: recordsArray)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func saveDataDB(data: [AdministrationRecordAPI]) {
        resetDB()
        batchInsertAdministrationRecords(administrationRecords: data)
    }
    
    func resetDB() {
        let moc = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AdministrationRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try moc.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func batchInsertAdministrationRecords(administrationRecords: [AdministrationRecordAPI]) {
        guard !administrationRecords.isEmpty else { return }
        persistentContainer.performBackgroundTask({ (moc) in
            let batchInsert = self.batchInsertRequest(administrationRecords: administrationRecords)
            do {
                let batchInsertResult = try moc.execute(batchInsert) as? NSBatchInsertResult
                let insertSuccess = batchInsertResult?.result
                print("CoreData insert status: \(insertSuccess!)")
                self.getDataDB()
            } catch {
                moc.rollback()
            }
        })
    }
    
    func batchInsertRequest(administrationRecords: [AdministrationRecordAPI]) -> NSBatchInsertRequest {
        var index = 0
        let total = administrationRecords.count
        
        let batchInsert = NSBatchInsertRequest(entity: AdministrationRecord.entity()) { (managedObject: NSManagedObject) -> Bool in
            
            guard index < total else { return true }
            
            if let record = managedObject as? AdministrationRecord {
                let data = administrationRecords[index]
                record.date = data.date
                record.firstDose = data.firstDose
                record.secondDose = data.secondDose
                record.region = data.region
            }
            index += 1
            return false
        }
        
        return batchInsert
    }
    
    /*fetch data from db. should return array of arrays
     ["region", "first_dose_aggregate", "second_dose_aggregate"]*/
    
    func getDataDB () {
        var dosesPerRegion = [Int32]()
        let regions = ["Flanders", "Wallonia", "Brussels", "Ostbelgien"]
        let doseTypes = ["firstDose", "secondDose"]
        for region in regions {
            for doseType in doseTypes {
                let input = getDataDBPerRegion(region, doseType)
                if input != 0 {
                    dosesPerRegion.append(input)
                    }
                }
            }
        
        func getDataDBPerRegion(_ region: String, _ doseType: String) -> Int32 {
            let moc = persistentContainer.viewContext
            let keypath = NSExpression(forKeyPath: doseType)
            let expression = NSExpression(forFunction: "sum:", arguments: [keypath])

            let sumDesc = NSExpressionDescription()
            sumDesc.expression = expression
            sumDesc.name = "sum"
            sumDesc.expressionResultType = .integer32AttributeType

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AdministrationRecord")
            request.predicate = NSPredicate(format: "region like %@", region)
            request.returnsObjectsAsFaults = false
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [sumDesc]

            var resultSum: [[String:Any]]?
            
            do {
                resultSum = try moc.fetch(request) as? [[String:Any]]
                
                if let input = resultSum?[0]["sum"] as? Int32 {
                    return input
                }
                //dosesPerRegion.append(input)
            } catch {
                print("fetch request failed")
            }
            
            return 0
        }
    }
    
    func createChart() {
        
        //create bar chart
        let groupedBarChart = BarChartView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width))
        
        //chart configuration
        let xAxis = groupedBarChart.xAxis
        xAxis.labelPosition = .bottom
        
        groupedBarChart.rightAxis.enabled = false
        let yAxis = groupedBarChart.leftAxis
        
        
        //egend configuration
        let legend = groupedBarChart.legend
        
        //supply data
        var entries = [BarChartDataEntry]()
        
        for x in 0..<10 {
            entries.append(BarChartDataEntry(x: Double(x),
                                             y: Double.random(in: 0...30)))
        }
        let set = BarChartDataSet(entries: entries, label: "Cost")
        let data = BarChartData(dataSet: set)
        
        groupedBarChart.data = data
        
        view.addSubview(groupedBarChart)
        groupedBarChart.center = view.center
        
    }
}
