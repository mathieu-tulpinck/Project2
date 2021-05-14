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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        stackedBarChart = createChart()
        view.addSubview(stackedBarChart)
        stackedBarChart.center = view.center
        stackedBarChart.setNeedsDisplay()
        
        getData()
        
    }
    
    func getData() {
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
        
        func getDataDBPerRegion(_ region: String, _ doseType: String) -> Double {
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
                
                if let input = resultSum?[0]["sum"] as? Double {//not tested
                    return input
                }
            } catch {
                print("fetch request failed")
            }
            
            return 0
        }
        
        supplyData(input: dosesPerRegion)
    }
    
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
                
        return stackedBarChart
    }
    
    func supplyData(input: [Double]) {
        var yVals = [[Double]]()
        var entries = [BarChartDataEntry]()
        
        let percentagesPerRegion = calculatePercentage(input: input)
        
        for i in stride(from: 0, to: percentagesPerRegion.endIndex, by: 2) {
            yVals.append([percentagesPerRegion[i], percentagesPerRegion[i+1]])
        }
        print(yVals)
        
        for i in 0..<4 {
            let entry = BarChartDataEntry(x: Double(i), yValues: [yVals[i][1], yVals[i][0]])
            entries.append(entry)
        }
        print(entries)
        
        let dataSet = BarChartDataSet(entries: entries, label: "")
        dataSet.colors = [ChartColorTemplates.colorful()[1], ChartColorTemplates.joyful()[4]]
        dataSet.stackLabels = ["fully vaccinated", "partially vaccinated"]
        dataSet.drawValuesEnabled = false
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        stackedBarChart.data = BarChartData(dataSet: dataSet)
        stackedBarChart.fitBars = true
        stackedBarChart.animate(yAxisDuration: 2.5)
    }
    
    func calculatePercentage(input: [Double]) -> [Double] {
        var percentagesPerRegion = [Double]()
        let totalPopulationFlanders = Double(6629143)
        let totalPopulationWallonia = Double(3645243)
        let totalPopulationBrussels = Double(1218255)
        let totalPopulationOstbelgien = Double(77949)
        
        var percentageFirstDoseFlanders = (input[0]/totalPopulationFlanders)
        let percentageSecondDoseFlanders = (input[1]/totalPopulationFlanders)
        percentageFirstDoseFlanders -= percentageSecondDoseFlanders
        var percentageFirstDoseWallonia = (input[2]/totalPopulationWallonia)
        let percentageSecondDoseWallonia = (input[3]/totalPopulationWallonia)
        percentageFirstDoseWallonia -= percentageSecondDoseWallonia
        var percentageFirstDoseBrussels = (input[4]/totalPopulationBrussels)
        let percentageSecondDoseBrussels = (input[5]/totalPopulationBrussels)
        percentageFirstDoseBrussels -= percentageSecondDoseBrussels
        var percentageFirstDoseOstbelgien = (input[6]/totalPopulationOstbelgien)
        let percentageSecondDoseOstbelgien = (input[7]/totalPopulationOstbelgien)
        percentageFirstDoseOstbelgien -= percentageSecondDoseOstbelgien
        
        percentagesPerRegion.append(percentageFirstDoseFlanders)
        percentagesPerRegion.append(percentageSecondDoseFlanders)
        percentagesPerRegion.append(percentageFirstDoseWallonia)
        percentagesPerRegion.append(percentageSecondDoseWallonia)
        percentagesPerRegion.append(percentageFirstDoseBrussels)
        percentagesPerRegion.append(percentageSecondDoseBrussels)
        percentagesPerRegion.append(percentageFirstDoseOstbelgien)
        percentagesPerRegion.append(percentageSecondDoseOstbelgien)
        
        print(percentagesPerRegion)
        return percentagesPerRegion
    }
}
