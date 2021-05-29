//
//  ComputationHelper.swift
//  Project2
//
//  Created by mathieu on 28/05/2021.
//

import Foundation

//Computes the percentages of first and second dose administrations per region. The hardcoded population numbers are from Statbel (2020-01-01).
struct ComputationHelper {
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
        
        return percentagesPerRegion
    }
}
