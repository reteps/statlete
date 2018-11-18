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
import M13Checkbox
import RxSwift
import RxCocoa

class IndividualStatsController: UIViewController {
    var athleteName = UserDefaults.standard.string(forKey: "athleteName")
    let sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var athleteID = UserDefaults.standard.integer(forKey: "athleteID")
    let chart = LineChartView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    var settingsView = UIView()
    var infoView = UIView()
    var events = [String: [String: [AthleteTime]]]()
    var lines = [LineChartDataSet]()
    let picker = UIPickerView()
    let pickerBar = UIToolbar()
    let selectedEvent = UITextField()
    let disposeBag = DisposeBag()
    let colors = [UIColor(hexString: "7ad3c0")!,
    UIColor(hexString: "61a3ce")!,
    UIColor(hexString: "b283c6")!,
    UIColor(hexString: "c45850")!]
    // Takes an event and returns an array of lines based on the data
    func createLineChartData(event: [String: [AthleteTime]]?) -> [LineChartDataSet] {
        var lines = [LineChartDataSet]()
        if event == nil {
            return lines
        }
        let orderedYears = (event == nil) ? [String]() : event!.keys.sorted()
        // let orderedYears = eventKeys.sort(by: { Int($0) < Int($1) }).sorted()
        for i in 0..<orderedYears.count {
            // https://stackoverflow.com/questions/41720445/ios-charts-3-0-align-x-labels-dates-with-plots/41959257#41959257
            let year = orderedYears[i]
            let season = event![year]!
            var lineChartEntries = [ChartDataEntry]()
            for race in season {
                // https://stackoverflow.com/questions/52337853/date-from-calendar-datecomponents-returning-nil-in-swift/52337942
                var components = Calendar.current.dateComponents([.day, .month, .year], from: race.date)
                components.year = 2000
                let newDate = Calendar.current.date(from: components)
                let point = ChartDataEntry(x: newDate!.timeIntervalSince1970, y: race.time.timeIntervalSince1970)
                lineChartEntries.append(point)
            }
            let line = LineChartDataSet(values: lineChartEntries, label: String(year))
            // https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
            line.drawValuesEnabled = false
            line.lineWidth = 2
            line.circleColors = [self.colors[i]]
            line.colors = [self.colors[i]]
            lines.append(line)
        }
        return lines
    }

    // https://medium.com/app-coder-io/33-ios-open-source-libraries-that-will-dominate-2017-4762cf3ce449
    // Clears or Adds a line based on the checkbox value
    @objc func checkboxTapped(_ sender: M13Checkbox) {
        let lineIndex = sender.checkedValue! as! Int
        if sender.checkState == .checked {
            self.chart.data?.dataSets[lineIndex] = self.lines[lineIndex]
        } else {
            self.chart.data?.dataSets[lineIndex] = LineChartDataSet()
        }
        self.chart.data?.dataSets[lineIndex].notifyDataSetChanged()
        self.chart.data?.notifyDataChanged()
        self.chart.notifyDataSetChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // https://medium.com/@OsianSmith/creating-a-line-chart-in-swift-3-and-ios-10-2f647c95392e
        // https://blog.pusher.com/handling-internet-connection-reachability-swift/
        // Clears old checkboxes
        for view in self.settingsView.subviews {
            view.removeFromSuperview()
        }
        let athlete = individualAthlete(athleteID: self.athleteID, athleteName: self.athleteName!, type: self.sportMode!)!
        // TODO: event picker
        self.events = athlete.events
        let event = self.events.first?.value
        self.lines = createLineChartData(event: event)
        let orderedYears = (event == nil) ? [String]() : event!.keys.sorted()
        createChart(lines: lines, orderedYears: orderedYears)
        if event != nil {
            createCheckboxesAndConstrain(orderedYears: orderedYears)
        }
        self.picker.delegate = nil
        self.picker.dataSource = nil
        Observable.just(Array(self.events.keys)).bind(to: self.picker.rx.itemTitles) { _, item in
            return item
            }.disposed(by: disposeBag)
                // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/UIPickerViewExample/SimplePickerViewExampleViewController.swift
        // Constrains settingsView to contentView


    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        initScrollViewAndContent()
        initChart()
        initSettingsView()
        initInfoView()
        initPickerBar()
        initPickerView()
        initPicker()
    }
    func initSettingsView() {
        self.contentView.addSubview(self.settingsView)
        self.settingsView.snp.makeConstraints { (make) in
            make.top.equalTo(self.chart.snp.bottom).offset(20)
            make.left.equalTo(self.contentView).offset(20)
            make.right.equalTo(self.contentView.snp.centerX).offset(-20)
            make.bottom.equalTo(self.contentView)
        }
    }
    func initInfoView() {
        self.contentView.addSubview(self.infoView)
        self.infoView.snp.makeConstraints { (make) in
            make.top.equalTo(self.chart.snp.bottom).offset(20)
            make.left.equalTo(self.contentView.snp.centerX).offset(20)
            make.right.equalTo(self.contentView).offset(-20)
            make.bottom.equalTo(self.contentView)
        }
        
    }
    func initPickerView() {
        self.infoView.addSubview(self.selectedEvent)
        self.selectedEvent.text = "Change Event"
        self.selectedEvent.textColor = .black
        self.selectedEvent.isUserInteractionEnabled = true
        self.selectedEvent.inputView = self.picker
        self.selectedEvent.inputAccessoryView = self.pickerBar
        
        self.selectedEvent.snp.makeConstraints { (make) in
            
            make.edges.equalTo(self.infoView)
        }
    }
    func initPicker() {
        self.picker.backgroundColor = .white
        self.picker.rx.modelSelected(String.self).subscribe(onNext: { item in
            self.selectedEvent.resignFirstResponder()
            let event = self.events[item[0]]!
            self.lines = self.createLineChartData(event: event)
            let orderedYears = event.keys.sorted()
            self.createChart(lines: self.lines, orderedYears: orderedYears)
            for view in self.settingsView.subviews {
                view.removeFromSuperview()
            }
            self.createCheckboxesAndConstrain(orderedYears: orderedYears)
            
        }).disposed(by: disposeBag)

    }
    func initPickerBar() {
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
        doneButton.rx.tap.subscribe(onNext: { _ in
            self.selectedEvent.resignFirstResponder()
        }).disposed(by: disposeBag)
        self.pickerBar.setItems([doneButton], animated: false)
        self.pickerBar.sizeToFit()
        self.pickerBar.isUserInteractionEnabled = true

    }
    func initScrollViewAndContent() {
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
    func createChart(lines: [LineChartDataSet], orderedYears: [String]) {
        let data = LineChartData()
        for line in lines {
            data.addDataSet(line)
        }
        self.chart.data = data
        self.chart.leftAxis.valueFormatter = MyDateFormatter("mm:s.S")
        self.chart.chartDescription?.text = self.athleteName!
        let marker = BalloonMarker(color: UIColor.white, font: UIFont(name: "Helvetica", size: 12)!, textColor: UIColor.black, insets: UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0), years: orderedYears)
        marker.minimumSize = CGSize(width: 75.0, height: 35.0)
        self.chart.marker = marker
        // https://github.com/danielgindi/Charts/issues/943

    }
    func initChart() {
        self.contentView.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView)
            make.left.right.equalTo(self.contentView)
            make.height.equalTo(self.scrollView)
        }
        self.chart.xAxis.valueFormatter = MyDateFormatter("MMM dd")
        self.chart.xAxis.labelPosition = .bottom
        self.chart.rightAxis.enabled = false
        // https://github.com/PhilJay/MPAndroidChart/wiki
        // https://stackoverflow.com/questions/38212750/create-a-markerview-when-user-clicks-on-chart

        self.chart.chartDescription?.textColor = UIColor.black
        self.chart.chartDescription?.position = CGPoint(x: self.chart.frame.width / 2, y: self.chart.frame.height - 30)
    }
    class CustomizedCheckBox {
        let checkbox: M13Checkbox
        init() {
            checkbox = M13Checkbox()
            checkbox.setCheckState(.checked, animated: false)
            checkbox.stateChangeAnimation = .bounce(.fill)
            checkbox.secondaryTintColor =  UIColor(hexString: "47cae8")
            checkbox.secondaryCheckmarkTintColor = .white //checkmark
            checkbox.tintColor = UIColor(hexString: "53cce7")
        }
    }
    func createCheckboxesAndConstrain(orderedYears: [String]) {
        var checks = [M13Checkbox]()
        // Constrains checkboxes + label to settingsView
        for (i, year) in orderedYears.enumerated() {
            let checkbox = CustomizedCheckBox().checkbox
            self.settingsView.addSubview(checkbox)
            let label = UILabel()
            checkbox.checkedValue = i
            checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: UIControlEvents.valueChanged)
            self.settingsView.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.left.equalTo(checkbox.snp.right)
                make.top.bottom.equalTo(checkbox)
                make.right.equalTo(self.settingsView)
            }
            label.text = year
            label.textColor = .black
            checks.append(checkbox)
        }
        // TODO UIStack View
        // Constrains first checkbox to settingsView frame
        checks[0].snp.makeConstraints { (make) in
            make.top.equalTo(self.settingsView)
            make.left.equalTo(self.settingsView)
            make.width.height.equalTo(50)
        }
        // Constrains last checkbox to settingsView frame
        checks[checks.count - 1].snp.makeConstraints { (make) in
            make.bottom.equalTo(self.settingsView)
        }
        // Constrains checkboxes to each other
        for i in 0..<checks.count - 1 {
            let checkbox = checks[i]
            let nextCheckbox = checks[i+1]
            checkbox.snp.makeConstraints { (make) in
                make.bottom.equalTo(nextCheckbox.snp.top)
            }
            nextCheckbox.snp.makeConstraints { (make) in
                make.width.height.equalTo(50)
                make.left.equalTo(self.settingsView)
                make.top.equalTo(checkbox.snp.bottom)
            }
        }
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
