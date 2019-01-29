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
import FontAwesome_swift

class IndividualStatsController: UIViewController {
    // Defaults
    var athleteName = UserDefaults.standard.string(forKey: "athleteName")
    var sportMode = UserDefaults.standard.string(forKey: "sportMode")
    var athleteID = UserDefaults.standard.integer(forKey: "athleteID")
    var shouldUpdateData = true // This will be set by other functions
    // UI Elements
    let chart = LineChartView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    var settingsView = UIView()
    var checkboxView = UIView()
    let infoView = UIView()
    /*
    ScrollView
    -> ContentView
        -> Settings        |   Info
            -> Checkbox       -> Label
    */
    let eventTapButton = UIBarButtonItem()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    // Variables
    var lines = [LineChartDataSet]()
    var events = [String: [String: [AthleteTime]]]()
    let colors = [UIColor(rgb: 0x7ad3c0),
    UIColor(rgb: 0x61a3ce),
    UIColor(rgb: 0xb283c6),
    UIColor(rgb: 0xc45850)]
    let disposeBag = DisposeBag()
    var timeFormatter = DateFormatter()
    var selectedEventName = ""
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // https://medium.com/@OsianSmith/creating-a-line-chart-in-swift-3-and-ios-10-2f647c95392e
        // https://blog.pusher.com/handling-internet-connection-reachability-swift/
        if shouldUpdateData {
            reloadData()
            createPage()
            shouldUpdateData.toggle()
        } else {
            print("[INFO]: data not updating")
        }
        // https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Examples/UIPickerViewExample/SimplePickerViewExampleViewController.swift
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    func initUI() {
        self.view.backgroundColor = .white
        
        initScrollViewAndContent()
        initChart()
        
        initSettingsView()
        initCheckBoxView()
        
        initInfoView()
        initNavBar()
        // initRefreshControl()
    }
    func initNavBar() {
        titleButton.rx.tap.subscribe(onNext: { _ in
            print("tapped")
        })
        titleButton.sizeToFit()
        self.navigationItem.titleView = titleButton

        eventTapButton.title = "Event"
        let eventSelection = EventSelection()
        self.navigationItem.leftBarButtonItem = eventTapButton
        eventTapButton.rx.tap.subscribe(onNext: { _ in
            self.navigationController?.present(eventSelection, animated: true)
        })
    }
    

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

    func initRefreshControl() {
        let refreshControl = UIRefreshControl()
        let title = NSLocalizedString("Refreshing Data", comment: "Pull to refresh")
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.rx.controlEvent(.valueChanged).subscribe ( onNext: { _ in
            print("refresh")
            self.createPage()
            refreshControl.endRefreshing()
        })
        scrollView.refreshControl = refreshControl
    }
    func reloadData() { // athlete has changed
        let athlete = individualAthlete(athleteID: self.athleteID, athleteName: self.athleteName!, type: self.sportMode!)!
        
        self.events = athlete.events
        self.selectedEventName = self.events.first?.key ?? ""
        /*Observable.just(Array(self.events.keys)).bind(to: self.picker.rx.itemTitles) { _, item in
            return item
        }.disposed(by: disposeBag)*/
        titleButton.setTitle(self.athleteName!, for: .normal)
        titleButton.sizeToFit()


    }
    func createPage() { // event has changed
        let event = self.events[self.selectedEventName]
        self.lines = self.createLineChartData(event: event)
        let orderedYears = (event == nil) ? [String]() : event!.keys.sorted()
        self.createChart(lines: self.lines, orderedYears: orderedYears)
        for view in self.checkboxView.subviews {
            view.removeFromSuperview()
        }
        if event != nil {
            self.createCheckboxesAndConstrain(records: self.recordDict(event: event!))
        }
    }
    func recordDict(event: [String: [AthleteTime]]) -> [String: String] {
        self.timeFormatter.dateFormat = "mm:ss.SS"
        var times = [String: String]()
        for (year, data) in event {
            if (data.count == 0) {
                times[year] = "N/A"
                continue
            }
            let fastest = data.max { $0.time > $1.time }
            let formattedTime = self.timeFormatter.string(from: fastest!.time)
            times[year] = formattedTime
        }
        return times
    }
    func initCheckBoxView() {
        self.settingsView.addSubview(self.checkboxView)
        self.checkboxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
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
        self.contentView.addSubview(infoView)
        self.infoView.snp.makeConstraints { (make) in
            make.top.equalTo(self.chart.snp.bottom).offset(20)
            make.left.equalTo(self.contentView.snp.centerX).offset(20)
            make.right.equalTo(self.contentView).offset(-20)
            make.bottom.equalTo(self.contentView)
        }
        
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
        let marker = BalloonMarker(color: UIColor.white, font: UIFont(name: "Helvetica", size: 12)!, textColor: UIColor.black, insets: UIEdgeInsets(top: 5, left: 5, bottom: 10.0, right: 5), years: orderedYears)
        marker.minimumSize = CGSize(width: 50.0, height: 20.0)
        marker.chartView = self.chart
        self.chart.marker = marker
        // https://github.com/danielgindi/Charts/issues/943

    }
    func initChart() {
        self.contentView.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            make.top.left.equalTo(self.contentView)
            make.height.equalTo(self.scrollView)
            make.right.equalTo(self.contentView)//.offset(-20)
        }
        self.chart.xAxis.valueFormatter = MyDateFormatter("MMM dd")
        self.chart.xAxis.labelPosition = .bottom
        self.chart.rightAxis.enabled = false
        self.chart.drawBordersEnabled = true
        self.chart.minOffset = 20
        // https://github.com/PhilJay/MPAndroidChart/wiki
        // https://stackoverflow.com/questions/38212750/create-a-markerview-when-user-clicks-on-chart
    }
    class CustomizedCheckBox {
        let checkbox: M13Checkbox
        init() {
            checkbox = M13Checkbox()
            checkbox.setCheckState(.checked, animated: false)
            checkbox.stateChangeAnimation = .bounce(.fill)
            checkbox.secondaryTintColor =  UIColor(rgb: 0x47cae8)
            checkbox.secondaryCheckmarkTintColor = .white //checkmark
            checkbox.tintColor = UIColor(rgb: 0x53cce7)
            checkbox.boxType = .square
        }
    }
    func createCheckboxesAndConstrain(records: [String: String]) {
        var checks = [M13Checkbox]()
        // Constrains checkboxes + label to settingsView
        let orderedYears = records.keys.sorted()
        for (i, year) in orderedYears.enumerated() {
            let checkbox = CustomizedCheckBox().checkbox
            let label = UILabel()
            let recordLabel = UILabel()

            self.checkboxView.addSubview(checkbox)
            self.checkboxView.addSubview(label)
            self.checkboxView.addSubview(recordLabel) // also clear this
            checkbox.checkedValue = i
            checkbox.rx.controlEvent(UIControlEvents.valueChanged).subscribe(onNext: { [unowned self] _ in
                let lineIndex = checkbox.checkedValue! as! Int
                if checkbox.checkState == .checked {
                    self.chart.data?.dataSets[lineIndex] = self.lines[lineIndex]
                } else {
                    self.chart.data?.dataSets[lineIndex] = LineChartDataSet()
                }
                self.chart.data?.dataSets[lineIndex].notifyDataSetChanged()
                self.chart.data?.notifyDataChanged()
                self.chart.notifyDataSetChanged()
            })
            label.snp.makeConstraints { (make) in
                make.left.equalTo(checkbox.snp.right).offset(10)
                make.top.bottom.equalTo(checkbox)
                make.right.equalTo(self.checkboxView)
            }
            recordLabel.snp.makeConstraints { make in
                make.top.bottom.equalTo(checkbox)
                make.left.right.equalTo(self.infoView)
            }
            
            recordLabel.text = records[year]
            label.text = year
            label.textColor = .black
            checks.append(checkbox)
        }
        // Constrains first checkbox to settingsView frame
        checks[0].snp.makeConstraints { (make) in
            make.top.equalTo(self.checkboxView)
            make.left.equalTo(self.checkboxView)
            make.width.height.equalTo(30)
        }
        // Constrains last checkbox to checkboxView frame
        checks[checks.count - 1].snp.makeConstraints { (make) in
            make.bottom.equalTo(self.checkboxView).offset(-30)
        }
        // Constrains checkboxes to each other
        for i in 0..<checks.count - 1 {
            let checkbox = checks[i]
            let nextCheckbox = checks[i+1]
            checkbox.snp.makeConstraints { (make) in
                make.bottom.equalTo(nextCheckbox.snp.top).offset(-10)
            }
            nextCheckbox.snp.makeConstraints { (make) in
                make.width.height.equalTo(30)
                make.left.equalTo(self.checkboxView)
                make.top.equalTo(checkbox.snp.bottom).offset(10)
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

extension IndividualStatsController: UIToolbarDelegate {
    func position(for: UIBarPositioning) -> UIBarPosition {
        print("hello")
        return .topAttached
    }
}
