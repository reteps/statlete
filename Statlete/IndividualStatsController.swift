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
        let fastest = 0.0//event.values.max { $0.fastest!.time > $1.fastest!.time}?.fastest!.time.timeIntervalSince1970
        let earliest = 0.0//event.values.min { $0.earliest!.date > $1.earliest!.date}?.earliest!.date.timeIntervalSince1970
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
                let point = ChartDataEntry(x: newDate!.timeIntervalSince1970 - earliest, y: race.time.timeIntervalSince1970 - fastest)
                lineChartEntries.append(point)
            }
            let line = LineChartDataSet(values: lineChartEntries, label: year)
            // https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
            line.colors = [UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1.0)]
            line.valueFormatter = ValueFormatter(year)
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
        // https://github.com/danielgindi/Charts/issues/943
        self.chart.leftAxis.valueFormatter = MyDateFormatter("mm.ss")
        self.chart.xAxis.valueFormatter = MyDateFormatter("MMM dd")
        self.chart.marker = MyMarkerView()
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
    class MyDateFormatter: IAxisValueFormatter {
        
        let timeFormatter: DateFormatter
        
        init(_ format: String) {
            // https://stackoverflow.com/questions/40648284/converting-a-unix-timestamp-into-date-as-string-swift
            timeFormatter = DateFormatter()
            timeFormatter.dateFormat = format
        }
        
        public func stringForValue(_ timestamp: Double, axis: AxisBase?) -> String {
            let date = Date(timeIntervalSince1970: timestamp)
            return timeFormatter.string(from: date)
        }
    }
    class MyMarkerView: MarkerView {
        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            print("entry selected")
        }
    }
    class ValueFormatter: IValueFormatter {
        let valueFormatter: DateFormatter
        init(_ year: String) {
            valueFormatter = DateFormatter()
            valueFormatter.dateFormat = "MMM dd \(year)"
        }

        func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
            print(entry, value)
            let date = Date(timeIntervalSince1970: value)
            return valueFormatter.string(from: date)
        }
        

    }

}
