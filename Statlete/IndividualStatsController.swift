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
import Checkbox
class IndividualStatsController: UIViewController {
    var athleteName = UserDefaults.standard.string(forKey: "athleteName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var athleteID = UserDefaults.standard.integer(forKey: "athleteID")
    let chart = LineChartView()
    let scrollView = UIScrollView()
    func createLineChartData(event: [String: AthleteSeason]) -> [LineChartDataSet] {
        let fastest = 0.0//event.values.max { $0.fastest!.time > $1.fastest!.time}?.fastest!.time.timeIntervalSince1970
        let earliest = 0.0//event.values.min { $0.earliest!.date > $1.earliest!.date}?.earliest!.date.timeIntervalSince1970
        let colors = [UIColor(hexString: "7ad3c0")!,
                      UIColor(hexString: "61a3ce")!,
        UIColor(hexString: "b283c6")!,
        UIColor(hexString: "c45850")!]
        var lines = [LineChartDataSet]()
        let orderedYears = event.keys.sorted()
        // let orderedYears = eventKeys.sort(by: { Int($0) < Int($1) }).sorted()
        for i in 0..<orderedYears.count {
            // https://stackoverflow.com/questions/41720445/ios-charts-3-0-align-x-labels-dates-with-plots/41959257#41959257
            let year = orderedYears[i]
            let season = event[year]!
            var lineChartEntries = [ChartDataEntry]()
            for race in season.times {
                // https://stackoverflow.com/questions/52337853/date-from-calendar-datecomponents-returning-nil-in-swift/52337942
                var components = Calendar.current.dateComponents([.day, .month, .year], from: race.date)
                components.year = 2000
                let newDate = Calendar.current.date(from: components)
                let point = ChartDataEntry(x: newDate!.timeIntervalSince1970 - earliest, y: race.time.timeIntervalSince1970 - fastest)
                lineChartEntries.append(point)
            }
            let line = LineChartDataSet(values: lineChartEntries, label: String(year))
            // https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
            line.drawValuesEnabled = false
            line.lineWidth = 2
            line.circleColors = [colors[i]]//setCircleColor( Color.BLACK );
            line.colors = [colors[i]]
            // line.valueFormatter = ValueFormatter(year)
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
        createChart(event: event)
        let orderedYears = event.keys.sorted()
        for year in orderedYears {
            M13Chec
        }



    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        let contentView = UIView()
        self.scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            //make.edges.equalTo(self.scrollView)
            make.top.bottom.equalTo(self.scrollView)
            make.left.right.equalTo(self.view)
            make.width.equalTo(self.scrollView)
        }
        // https://stackoverflow.com/questions/2944294/how-do-i-auto-size-a-uiscrollview-to-fit-the-content
        contentView.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            // http://snapkit.io/docs/
            make.top.equalTo(contentView)
            make.left.right.equalTo(contentView)
            // https://github.com/SnapKit/SnapKit/issues/448
            make.height.equalTo(self.view).offset(-(self.tabBarController?.tabBar.frame.height)!)
        }
        self.scrollView.contentSize = contentView.frame.size
        // https://stackoverflow.com/questions/10518790/how-to-set-content-size-of-uiscrollview-dynamically
    }
    func createChart(event: [String: AthleteSeason]) {
        
        let lines = createLineChartData(event: event)
        let data = LineChartData()
        for line in lines {
            data.addDataSet(line)
        }
        self.chart.data = data
        // https://github.com/danielgindi/Charts/issues/943
        self.chart.leftAxis.valueFormatter = MyDateFormatter("mm:s.S")
        self.chart.xAxis.valueFormatter = MyDateFormatter("MMM dd")
        self.chart.xAxis.labelPosition = .bottom
        self.chart.rightAxis.enabled = false
        // https://github.com/PhilJay/MPAndroidChart/wiki
        let orderedYears = event.keys.sorted()
        // https://stackoverflow.com/questions/38212750/create-a-markerview-when-user-clicks-on-chart
        let marker = BalloonMarker(color: UIColor.white, font: UIFont(name: "Helvetica", size: 12)!, textColor: UIColor.black, insets: UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0), years: orderedYears)
        marker.minimumSize = CGSize(width: 75.0, height: 35.0)
        self.chart.marker = marker
        self.chart.chartDescription?.text = self.athleteName!
        self.chart.chartDescription?.textColor = UIColor.black
        self.chart.chartDescription?.position = CGPoint(x: self.chart.frame.width / 2, y: self.chart.frame.height - 30)
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
}
