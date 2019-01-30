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
import RealmSwift
import SwiftyJSON

struct currentState {
    var sport: Sport
    var event: String
    var id: String
    var name: String
    var team: Team
    init(sport:Sport=Sport.None,event:String="",id:String="",name:String="",team:Team=Team()) {
        self.sport = sport
        self.event = event
        self.id = id
        self.name = name
        self.team = team
    }
}
class IndividualStatsController: UIViewController {

    let chart = LineChartView()
    var scrollView = UIScrollView()
    var contentView = UIView()
    var settingsView = UIView()
    var checkboxView = UIView()
    let infoView = UIView()
    let eventTapButton = UIBarButtonItem()
    var titleButton: UIButton = {
        let b = UIButton(type: .system)
        b.tintColor = .black
        b.setImage(UIImage.fontAwesomeIcon(name: .chevronDown, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20)), for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        return b
    }()
    var athlete = Athlete()
    // Needed for Event Switching
    var otherSportName = Sport.None
    var otherSportEvents = [String]()
    var state = currentState()
    var lines = [LineChartDataSet]()
    let disposeBag = DisposeBag()
    var timeFormatter = DateFormatter()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData(newAthlete: false)
        createPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[info] view loading")
        initState()
        reloadData()
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
        let athletePicker = AthleteSearchController()
        titleButton.rx.tap.flatMap { _ -> PublishSubject<AthleteResult> in
            athletePicker.team = self.state.team
            self.navigationController?.pushViewController(athletePicker, animated: true)
            return athletePicker.selectedAthlete
        }.subscribe(onNext: { athlete in
            self.state.id = athlete.id
            self.state.name = athlete.name

            athletePicker.navigationController?.popViewController(animated: true)
            self.reloadData(newAthlete: true)
            self.createPage()

        }).disposed(by: disposeBag)
        titleButton.sizeToFit()
        self.navigationItem.titleView = titleButton

        eventTapButton.title = "Event"
        let eventSelection = EventSelection()
        self.navigationItem.leftBarButtonItem = eventTapButton


        eventTapButton.rx.tap.flatMap { _ -> PublishSubject<[Sport:String]> in
            eventSelection.data = Dictionary(uniqueKeysWithValues:
                self.athlete.events.map { sport, events in
                    (sport, Array(events.keys))
                }
            )
            
            self.navigationController?.pushViewController(eventSelection, animated: true)
            return eventSelection.eventSelected
        }.subscribe(onNext: { [unowned self] event in
                self.state.sport = event.keys.first!
                self.state.event = event.values.first!
                self.reloadData(newAthlete: false)
                self.createPage()
        }).disposed(by: disposeBag)
    }
    
    // Takes an event and returns an array of lines based on the data
    func createLineChartData(event: [String: [AthleteTime]]) -> [LineChartDataSet] {
        var lines = [LineChartDataSet]()
        let colors = [
            UIColor(rgb: 0x7ad3c0),
            UIColor(rgb: 0x61a3ce),
            UIColor(rgb: 0xb283c6),
            UIColor(rgb: 0xc45850)]
        let orderedYears = event.keys.sorted()
        for (index, year) in orderedYears.enumerated() {
            let season = event[year]!
            var lineChartEntries = [ChartDataEntry]()
            for race in season {
                // Format Date (Strips Year)
                var components = Calendar.current.dateComponents([.day, .month, .year], from: race.date)
                components.year = 2000
                let newDate = Calendar.current.date(from: components)!
                let point = ChartDataEntry(x: newDate.timeIntervalSince1970, y: race.time.timeIntervalSince1970)
                lineChartEntries.append(point)
            }
            let line = LineChartDataSet(values: lineChartEntries, label: year)
            line.drawValuesEnabled = false
            line.lineWidth = 2
            line.circleColors = [colors[index]]
            line.colors = [colors[index]]
            lines.append(line)
        }
        return lines
    }
    
    func initRefreshControl() {
        let refreshControl = UIRefreshControl()
        let title = NSLocalizedString("Refreshing Data...", comment: "Pull to refresh")
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.rx.controlEvent(.valueChanged).subscribe ( onNext: { _ in
            self.reloadData(newAthlete: true)
            self.createPage()
            refreshControl.endRefreshing()
        }).disposed(by: disposeBag)
        scrollView.refreshControl = refreshControl
    }
    // Grabs new information
    func initState() {
        let realms = try! Realm()
        let settings = realms.objects(Settings.self).first!
        self.state.sport = Sport(rawValue: settings.sport)!
        self.state.id = settings.athleteID
        self.state.name = settings.athleteName
        self.state.team = Team(name: settings.teamName, code: settings.teamID)
        reloadData(newAthlete: true)
        createPage()
    }
    func reloadData(newAthlete: Bool = false) {
        // 4 cases:
        // Settings -> grab new data
        // Change Event -> don't grab new data
        // Change Athlete -> grab new data
        // Refresh -> grab new data

        if newAthlete {
            self.athlete = individualAthlete(id: state.id, name: state.name, bothSports:true)!
            self.state.event = self.athlete.events.first?.value.first?.key ?? ""
            titleButton.setTitle(state.name, for: .normal)
            titleButton.sizeToFit()
        }
        eventTapButton.title = state.event
        // Set new title



    }
    // Creates a page using the selected eventName
    func createPage() {
        let event = self.athlete.events[self.state.sport]?[self.state.event]
        if event != nil {
            self.lines = self.createLineChartData(event: event!)
            // Need self for checkboxes
            let orderedYears = event!.keys.sorted()
            drawChart(lines: lines, orderedYears: orderedYears)
            
            for view in self.checkboxView.subviews {
                view.removeFromSuperview()
            }
            self.createCheckboxesAndConstrain(records: findRecords(event: event!))
        }

    }
    // Returns the records for an event
    func findRecords(event: [String: [AthleteTime]]) -> [String: String] {
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
    func initChart() {
        self.contentView.addSubview(self.chart)
        self.chart.snp.makeConstraints { (make) in
            make.top.left.equalTo(self.contentView)
            make.height.equalTo(self.scrollView)
            make.right.equalTo(self.contentView)
        }
        self.chart.xAxis.valueFormatter = MyDateFormatter("MMM dd")
        self.chart.xAxis.labelPosition = .bottom
        self.chart.rightAxis.enabled = false
        self.chart.drawBordersEnabled = true
        self.chart.minOffset = 20
    }

    func initScrollViewAndContent() {
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
        self.scrollView.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { (make) in
            make.edges.width.equalTo(self.scrollView)
        }
    }
    // Draws the specified lines on the chart
    func drawChart(lines: [LineChartDataSet], orderedYears: [String]) {
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
    }

    // This Function Sucks!!!
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

class MyDateFormatter: IAxisValueFormatter {
    
    let timeFormatter = DateFormatter()
    
    init(_ format: String) {
        timeFormatter.dateFormat = format
    }
    
    public func stringForValue(_ timestamp: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return timeFormatter.string(from: date)
    }
}
