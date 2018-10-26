//
//  TeamStatsController.swift
//  Statlete
//
//  Created by Peter Stenger on 9/28/18.
//  Copyright © 2018 Peter Stenger. All rights reserved.
//

import UIKit
import Charts

class TeamStatsController: UIViewController {
    var schoolName = UserDefaults.standard.string(forKey: "schoolName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var schoolID = UserDefaults.standard.string(forKey: "schoolID")
    let chart = LineChartView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        constrainScollAndContent()
        self.contentView.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView)
            make.left.right.equalTo(self.contentView)
            make.height.equalTo(self.scrollView)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let times = teamTimes(type: self.sportMode!, teamID: self.schoolID!)
        let line = createLine(meetEvent: times["5,000 Meters"]!, sortIndex: 7)
        createChart(lines: [line])
        
        
    }
    func createChart(lines: [LineChartDataSet]) {
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
        self.chart.chartDescription?.text = self.schoolName!
        let marker = BalloonMarker(color: UIColor.blue, font: UIFont(name: "Helvetica", size: 12)!, textColor: UIColor.black, insets: UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0))
        print("marker = \(marker)")
        marker.minimumSize = CGSize(width: 75.0, height: 35.0)
        self.chart.marker = marker
        
        self.chart.chartDescription?.textColor = UIColor.black
        self.chart.chartDescription?.position = CGPoint(x: self.chart.frame.width / 2, y: self.chart.frame.height - 30)
    }
    func createLine(meetEvent: [Date: Meet], sortIndex: Int?) -> LineChartDataSet {
        var dataSeries = [ChartDataEntry]()
        let orderedKeys = meetEvent.keys.sorted()
        var label = "Average Time"
        if sortIndex != nil {
            if sortIndex! > 0 {
                label += " (first \(sortIndex!))"
            } else {
                label += " (last \(abs(sortIndex!)))"
            }
        }
        for key in orderedKeys {
            let meet = meetEvent[key]!
            // https://stackoverflow.com/questions/28658264/how-do-i-get-a-tenth-part-of-a-second
            //https://stackoverflow.com/questions/28288148/making-my-function-calculate-average-of-array-swift
            //https://stackoverflow.com/questions/38248941/how-to-get-time-hour-minute-second-in-swift-3-using-nsdate
            let calendar = Calendar.current
            var times = meet.times.map( { (value: AthleteTime) -> Int in
                return calendar.component(.minute, from: value.time) * 60 + calendar.component(.second, from: value.time)
            })
            if sortIndex != nil {
                if sortIndex! > 0 {
                    times = Array(times.sorted().prefix(sortIndex!))
                } else {
                    times = Array(times.sorted().suffix(abs(sortIndex!)))
                }
            }
            let average = Int(Double(times.reduce(0, +)) / Double(times.count))
            let seconds = average % 60
            let minutes = Int(average / 60)
            print("\(minutes):\(seconds).00")
            let averageTime = formatEventTime(s: "\(minutes):\(seconds).00")
            dataSeries.append(ChartDataEntry(x: meet.date.timeIntervalSince1970, y: averageTime.timeIntervalSince1970))
        }
        
        let line = LineChartDataSet(values: dataSeries, label: label)
        // https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
        line.drawValuesEnabled = false
        line.lineWidth = 2
        line.circleColors = [UIColor.black]
        line.colors = [UIColor.black]
        return line
    }
    func constrainScollAndContent() {
        // https://stackoverflow.com/questions/2944294/how-do-i-auto-size-a-uiscrollview-to-fit-the-content
        // https://stackoverflow.com/questions/10518790/how-to-set-content-size-of-uiscrollview-dynamically
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            // https://stackoverflow.com/questions/52865569/uiscrollview-item-not-moving-from-the-background/52876135#52876135
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
        self.scrollView.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
        }
    }

}
