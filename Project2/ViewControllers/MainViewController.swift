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
    
    let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
    
    var stackedBarChart: BarChartView!
    //var label: UILabel!
    
    @IBOutlet weak var label: UILabel!
    @IBAction func getData(_ sender: UIBarButtonItem) {
        getData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //label = UILabel(frame: CGRect(x: 16, y: 30, width: 200, height: 21))
        label.font = UIFont.systemFont(ofSize: 10)
        
        stackedBarChart = createChart()
        view.addSubview(stackedBarChart)
        stackedBarChart.center = view.center
        
        getData()
    }
    
    //Function retrieves JSON data from API and stores it in Core Data.
    func getData() {
        let helper = FetchDataHelper()
        helper.fetchDataAPI { (response) in
            switch response {
            case .success(let returnedData):
                guard let recordsArray = returnedData.result["administered"] else { return }//AdministrationResponseAPI, a Dictionary, gets accessed to retrieve the array of AdministrationRecordAPI instances.
                if let dateStamp = recordsArray.last?.date {//Timestamp of last administration record added to the dataset is passed on to be visualised in the UI.
                    self.supplyData(input: dateStamp)
                }
                self.saveDataDB(data: recordsArray)//Administration records are passed on to be stored in persistence layer.
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
    
    //Inserts the administration records in batch into Core Data.
    func batchInsertAdministrationRecords(administrationRecords: [AdministrationRecordAPI]) {
        guard !administrationRecords.isEmpty else { return }
        persistentContainer.performBackgroundTask({ (moc) in//PerformBackgroundTask called on the persistence container to perform the batch insert on separate thread.
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
    
    //Preparation of batch insert request.
    func batchInsertRequest(administrationRecords: [AdministrationRecordAPI]) -> NSBatchInsertRequest {
        var index = 0
        let total = administrationRecords.count
        
        let batchInsert = NSBatchInsertRequest(entity: AdministrationRecord.entity()) { (managedObject: NSManagedObject) -> Bool in//Creates batch-insertion request for AdministrationRecord managed entity and specifies closure that inserts data into the entity.
            
            guard index < total else { return true }
            
            if let record = managedObject as? AdministrationRecord {
                let data = administrationRecords[index]//Maps attributes of AdministrationRecordRecordAPI instances to managed AdministrationRecord instances.
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
    
    //Fetches the administration records from Core Data for visualisation. The data retrieved is an aggregation of first and second dose administrations per region stored as an array of Double.
    func getDataDB () {
        var dosesPerRegion = [Double]()
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
        
        //Fetches the data per region using an aggregate NSExpressionDescription object and a predicate.
        func getDataDBPerRegion(_ region: String, _ doseType: String) -> Double {
            let moc = persistentContainer.viewContext
            let keypath = NSExpression(forKeyPath: doseType)
            let expression = NSExpression(forFunction: "sum:", arguments: [keypath])

            let sumDesc = NSExpressionDescription()//Allows to specify a virtual aggregation column to be returned from the
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
                if let input = resultSum?[0]["sum"] as? Double {
                    return input
                }
            } catch {
                print("fetch request failed")
            }
            
            return 0
        }
        
        supplyData(input: dosesPerRegion)
    }
    
    //Prepares the stacked bar chart with default values.
    func createChart() -> BarChartView {
        
        let stackedBarChart = BarChartView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width))
        
        let xAxis = stackedBarChart.xAxis
        xAxis.labelPosition = .bottom
        let regions = ["Flanders", "Wallonia", "Brussels", "Ostbelgien"]
        xAxis.valueFormatter = IndexAxisValueFormatter(values: regions)
        xAxis.granularity = 1
        
        stackedBarChart.rightAxis.enabled = false
        
        let yAxis = stackedBarChart.leftAxis
        yAxis.labelPosition = .outsideChart
        yAxis.axisMinimum = 0
        yAxis.labelCount = 10
        yAxis.axisMaximum = 1
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        yAxis.valueFormatter = DefaultAxisValueFormatter(formatter: formatter)
        
        var defaultEntries = [BarChartDataEntry]()
        for i in 0..<4 {
            let entry = BarChartDataEntry(x: Double(i), yValues: [0.0, 0.0])
            defaultEntries.append(entry)
        }
        
        let defaultDataSet = BarChartDataSet(entries: defaultEntries, label: "")
        defaultDataSet.stackLabels = ["fully vaccinated", "partially vaccinated"]
        defaultDataSet.drawValuesEnabled = false
        defaultDataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        stackedBarChart.data = BarChartData(dataSet: defaultDataSet)
        stackedBarChart.fitBars = true
        
        return stackedBarChart
    }
    
    //Updates the chart with the data retrieved from Core Data.
    func supplyData(input: [Double]) {
        var yVals = [[Double]]()
        var entries = [BarChartDataEntry]()
        
        let helper = ComputationHelper()
        let percentagesPerRegion = helper.calculatePercentage(input: input)
        
        for i in stride(from: 0, to: percentagesPerRegion.endIndex, by: 2) {
            yVals.append([percentagesPerRegion[i], percentagesPerRegion[i+1]])
        }
                
        for i in 0..<4 {
            let entry = BarChartDataEntry(x: Double(i), yValues: [yVals[i][1], yVals[i][0]])
            entries.append(entry)
        }
                
        let dataSet = BarChartDataSet(entries: entries, label: "")
        dataSet.colors = [ChartColorTemplates.colorful()[1], ChartColorTemplates.joyful()[4]]
        dataSet.stackLabels = ["fully vaccinated", "partially vaccinated"]
        dataSet.drawValuesEnabled = false
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        DispatchQueue.main.async {
            self.stackedBarChart.data = BarChartData(dataSet: dataSet)
            self.stackedBarChart.fitBars = true
            self.stackedBarChart.animate(yAxisDuration: 2.5)            
        }
    }
    
    func supplyData (input: String) {
        DispatchQueue.main.async {
            self.label.text = "data last updated: \(input)"
        }
    }
}
