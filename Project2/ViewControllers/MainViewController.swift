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
        batchInsertAdministrationRecords(administrationRecords: data)
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
        
        let batchInsert = NSBatchInsertRequest(
            entity: AdministrationRecord.entity()) { (managedObject: NSManagedObject) -> Bool in
            
            guard index < total else { return true }
            
            if let record = managedObject as? AdministrationRecord {
                let data = administrationRecords[index]
                record.date = data.date//date
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
        let moc = persistentContainer.viewContext
        let request = NSFetchRequest<AdministrationRecord>(entityName: "AdministrationRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "firstDose", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController?.performFetch()
            guard let administrationRecords = fetchedResultsController?.fetchedObjects else { return }
            for administrationRecord in administrationRecords {
                print("\(administrationRecord.date), \(administrationRecord.firstDose), \(administrationRecord.secondDose), \(administrationRecord.region)")
            }
            
        } catch {
            print("fetch request failed")
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
