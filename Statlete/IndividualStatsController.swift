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
    let chart = LineChartView()

    func createLineChartData(event: [String: AthleteSeason]) -> [LineChartDataSet] {
        let fastest = event.values.max { $0.fastest!.time > $1.fastest!.time}?.fastest!.date.timeIntervalSince1970
        let earliest = event.values.min { $0.earliest!.date > $1.earliest!.date}?.earliest!.time.timeIntervalSince1970
        var lines = [LineChartDataSet]()
        for (year, season) in event {
            // https://stackoverflow.com/questions/41720445/ios-charts-3-0-align-x-labels-dates-with-plots/41959257#41959257
            var lineChartEntries = [ChartDataEntry]()
            for race in season.times {
                print(race.date)
                // https://stackoverflow.com/questions/52337853/date-from-calendar-datecomponents-returning-nil-in-swift/52337942
                var components = Calendar.current.dateComponents([.day, .month, .year], from: race.date)
                components.year = 2000
                let newDate = Calendar.current.date(from: components)
                let point = ChartDataEntry(x: newDate!.timeIntervalSince1970 - earliest!, y: race.time.timeIntervalSince1970 - fastest!)
                lineChartEntries.append(point)
            }
            let line = LineChartDataSet(values: lineChartEntries, label: year)
            // https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
            line.colors = [UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1.0)]
            lines.append(line)
        }
        return lines
    }
    // https://medium.com/app-coder-io/33-ios-open-source-libraries-that-will-dominate-2017-4762cf3ce449
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // https://medium.com/@OsianSmith/creating-a-line-chart-in-swift-3-and-ios-10-2f647c95392e
        // https://blog.pusher.com/handling-internet-connection-reachability-swift/
        let athlete = individualAthlete(athleteID: self.athleteID, athleteName: self.athleteName!, type: self.sportMode!)!
        
        let event = athlete.events["5,000 Meters"]!
        let lines = createLineChartData(event: event)
        let data = LineChartData()
        for line in lines {
            data.addDataSet(line)
        }

        self.chart.data = data
        self.chart.chartDescription?.text = self.athleteName!
        self.chart.chartDescription?.textColor = UIColor.black
        self.chart.chartDescription?.position = CGPoint(x: self.chart.frame.width / 2, y: 30)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            // http://snapkit.io/docs/
            // top left bottom right
            make.edges.equalTo(self.view).inset(UIEdgeInsets(top: 30, left: 0, bottom: 50, right: 0))
        }
    }

}
