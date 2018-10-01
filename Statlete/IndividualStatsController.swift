//
//  IndividualAthleteController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/26/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import Charts
import SnapKit

class IndividualStatsController: UIViewController {
    var athleteName = UserDefaults.standard.string(forKey: "athleteName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var athleteID = UserDefaults.standard.integer(forKey: "athleteID")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // https://medium.com/@OsianSmith/creating-a-line-chart-in-swift-3-and-ios-10-2f647c95392e
        let athlete = individualAthlete(athleteID: self.athleteID, athleteName: self.athleteName!, type: self.sportMode!)!
        let chart = LineChartView()
        var lineChartEntries = [ChartDataEntry]()

        for event in athlete.events.values.first!.times {
            // https://stackoverflow.com/questions/41720445/ios-charts-3-0-align-x-labels-dates-with-plots/41959257#41959257
            let fastest = athlete.events.values.first!.fastest!.time.timeIntervalSince1970
            let first = athlete.events.values.first!.first!.date.timeIntervalSince1970
            let timeInSeconds = event.time.timeIntervalSince1970
            let dateInSeconds = event.date.timeIntervalSince1970
            let point = ChartDataEntry(x: dateInSeconds - first, y: timeInSeconds - fastest)
            print(point)
            lineChartEntries.append(point)
        }
        let line = LineChartDataSet(values: lineChartEntries, label: "Number")
        line.colors = [.blue]
        let data = LineChartData()
        data.addDataSet(line)
        chart.data = data
        chart.chartDescription?.text = "My awesome chart"
        self.view.addSubview(chart)
        print(athleteName)
        chart.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
            make.height.equalTo(500)
            make.width.equalTo(500)
        }
        print(sportMode)
        print(athleteID)
        print(athlete.name)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
