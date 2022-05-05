//
//  TimeLineViewController.swift
//  BidAsk
//
//  Created by Mac on 10/03/22.
//

import Foundation
import UIKit
import Charts
import Starscream
import Alamofire
import SafariServices


//xValues are declared as global because I needed to change the time interval for indexes to timestamps
var xValues = [Double]()
var selectedInterval : Interval? = .oneday
class TimeLineViewController : UIViewController, WebSocketDelegate, UITableViewDelegate, UITableViewDataSource, ChartViewDelegate {
    
    
    //MARK: - Outlets
    @IBOutlet weak var topHolderView: UIView!

    
    @IBOutlet weak var holderView: UIView!
    
    @IBOutlet weak var chartTitlleLabel: UILabel!
    
    @IBOutlet weak var dropDownImage: UIImageView!
    
    @IBOutlet weak var livePriceLabel: UILabel!
    @IBOutlet weak var timeIntervalTV: UITableView!
    @IBOutlet weak var candleStickChartView: CandleStickChartView!
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var changeGraphImageView: UIImageView!
    @IBOutlet weak var changeGraphHolderView: UIView!
    
    @IBOutlet weak var timeLineLabelHolderView: UIView!
    
    @IBOutlet weak var combineGraphView: CombinedChartView!
    
    @IBOutlet weak var barChartView: BarChartView!
    
    @IBOutlet weak var combinedCV2: CombinedChartView!
    
    //MARK: - Local Variables
    var socket : WebSocket!
    var priceSocket : WebSocket!
    var timeline = String()
    var initalDataModel = TimelineDataModel()
    var updatedDataModel = TimelineDataModel()
    var timelineDataModel = TimelineAPIDataModel()
    var timelineAPIData = [[Any]]()
    var isConnected = Bool()
    var isFirstTime = true
    var currentTimeStamp = Double()
    var lastTimeStamp = Double()
    let staticTimeIntervals : [Interval] = [Interval.onemin,Interval.fivemin,Interval.onehour,Interval.oneday,Interval.onemonth,Interval.oneweek]
    var initalSelection : [Bool] = [false,false,false,false,false,false]
    var priceModel = PriceDataModel()
    let markerView = CustomMarkerView()
    var selectedCoinPair = String()
    var movingAverageFor7 = [Double]()
    
   
    var lowValues = [Double]()
    var closeTime = [Double]()
    var closeValues = [Double]()
    var openValues = [Double]()
    var highValues = [Double]()
    var volumeValues = [Double]()
    //MARK: - Necessary Class functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getTimelineData()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.socket != nil {
            if !isFirstTime {
                self.disconnectRequest()
            }
        } else {
            return
        }
    }
    
    func initViews() {
        self.title = "Candlestick Graph for \(selectedCoinPair)"
        self.timeIntervalTV.delegate = self
        self.timeIntervalTV.dataSource = self
        self.timeIntervalTV.register(UINib(nibName: "CryptoTVC", bundle: nil), forCellReuseIdentifier: "CryptoTVC")
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        let change = UITapGestureRecognizer(target: self, action: #selector(changeGraph))
        self.timeLineLabelHolderView.addGestureRecognizer(tap)
        self.dropDownImage.transform = CGAffineTransform(rotationAngle: .pi)
        self.changeGraphHolderView.addGestureRecognizer(change)
        self.timeIntervalTV.isHidden = true
//        self.combineGraphView.isHidden = false
//        self.lineChartView.isHidden = false
//        self.candleStickChartView.isHidden = true
//        self.barChartView.isHidden = true
        candleStickChartView.delegate = self
        if #available(iOS 13.0, *) {
            self.dropDownImage.image = UIImage(systemName: "triangle.circle.fill")
            self.changeGraphImageView.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        } else {
            // Fallback on earlier versions
        }
    }
    
    //changing to different graph view
    @objc func changeGraph() {
//        self.candleStickChartView.isHidden = !self.candleStickChartView.isHidden
//        self.combineGraphView.isHidden = !self.combineGraphView.isHidden
//        self.barChartView.isHidden = !self.candleStickChartView.isHidden
        self.getTimelineData()
    }
    
    @objc func tapAction() {
        self.timeIntervalTV.isHidden = !self.timeIntervalTV.isHidden
        self.dropDownImage.transform = self.timeIntervalTV.isHidden ? CGAffineTransform(rotationAngle: .pi) : CGAffineTransform(rotationAngle: .pi*2)
    }
    
    
    //MARK: - Button Actions
    @IBAction func goToWebView(_ sender: Any) {
//        let urlString = "https://www.binance.com/en/trade/BTC_USDT?layout=pro"
//        guard let url = URL(string: urlString) else {return}
//        let vc = SFSafariViewController(url: url)
//        self.navigationController?.pushViewController(vc, animated: true)
        self.moveToLastX()
    }
    
    @IBAction func viewMACDBtnAction(_ sender: Any) {
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(withIdentifier: "CombinedChartVC")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Websocket functions
    
    func makeRequest() {
        let interval = selectedInterval?.description ?? Interval.oneday.description
        let urlString = "wss://stream.binance.com:9443/ws/\(selectedCoinPair.lowercased())@kline_\(interval)"
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func makePriceRequest() {
        let urlString = "wss://stream.binance.com:9443/ws/\(selectedCoinPair.lowercased())@trade"
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        self.priceSocket = WebSocket(request: request)
        self.priceSocket.delegate = self
        self.priceSocket.connect()
    }
    func disconnectRequest() {
        socket.disconnect()
        priceSocket.disconnect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
//            print("Received text: \(string)")
            let kline = "kline"
            let trade = "trade"
            let decoder = JSONDecoder()
            if string.contains(kline) {
                
                do {
                    self.updatedDataModel = try decoder.decode(TimelineDataModel.self, from: string.data(using: .utf8)!)
                    //                        self.removeLastValues()
                    self.currentTimeStamp = (updatedDataModel.timeline.startTime.description.toDouble()?.truncate(places: 6))!
                   if isFirstTime {
                        self.isFirstTime = false
                        self.lastTimeStamp = xValues.last ?? 0.0
                        self.customizeChart()
                        self.customizeLineChart()
                       self.customizeBarChart()
                       self.setCombinedChart()
                       self.setCombinedCV2()
                    }  else if self.currentTimeStamp == self.lastTimeStamp {
                        openValues[openValues.count - 1] = (updatedDataModel.timeline.open.description.toDouble()?.truncate(places: 6))!
                        closeValues[closeValues.count - 1] = (updatedDataModel.timeline.close.description.toDouble()?.truncate(places: 6))!
                        highValues[highValues.count - 1] = (updatedDataModel.timeline.high.description.toDouble()?.truncate(places: 6))!
                        lowValues[lowValues.count - 1] = (updatedDataModel.timeline.low.description.toDouble()?.truncate(places: 6))!
                        lastTimeStamp = (updatedDataModel.timeline.startTime.description.toDouble()?.truncate(places: 6))!
                        volumeValues[volumeValues.count - 1] = (updatedDataModel.timeline.volume.description.toDouble()?.truncate(places: 6))!
                        self.customizeChart()
                        self.customizeLineChart()
                        self.setCombinedChart()
                        self.customizeBarChart()
                        self.setCombinedCV2()
//                        self.checkLast()
                    }
                    else
                    {
                        if self.currentTimeStamp > self.lastTimeStamp {
                            xValues.append(updatedDataModel.timeline.startTime.description.toDouble()!)
                            closeTime.append(updatedDataModel.timeline.closeTime.description.toDouble()!)
                            openValues.append((updatedDataModel.timeline.open.description.toDouble()?.truncate(places: 6))!)
                            highValues.append((updatedDataModel.timeline.high.description.toDouble()?.truncate(places: 6))!)
                            lowValues.append((updatedDataModel.timeline.low.description.toDouble()?.truncate(places: 6))!)
                            closeValues.append((updatedDataModel.timeline.close.description.toDouble()?.truncate(places: 6))!)
                            volumeValues.append((updatedDataModel.timeline.volume.description.toDouble()?.truncate(places: 6))!)
                            self.lastTimeStamp = xValues.last ?? 0.0
                            self.customizeChart()
                            self.customizeLineChart()
                            self.setCombinedChart()
                            self.customizeBarChart()
                            self.setCombinedCV2()
                            self.checkLast()
                        }
                    }
                } catch {
                    print(error)
                }
                
            }
            if string.contains(trade) {
                do {
                    self.priceModel = try decoder.decode(PriceDataModel.self, from: string.data(using: .utf8)!)
                    self.livePriceLabel.text = "Live Price = \(priceModel.price.toDouble()?.removeZerosFromEnd() ?? "")"
                    
                } catch {
                    print(error)
                }
            }
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            print(error?.localizedDescription as Any)
        }
    }
    func removeLastValues () {
        xValues.removeLast()
        volumeValues.removeLast()
        closeTime.removeLast()
        lowValues.removeLast()
        highValues.removeLast()
        openValues.removeLast()
        closeValues.removeLast()
    }
    func removeAllValues () {
        xValues.removeAll()
        volumeValues.removeAll()
        closeTime.removeAll()
        highValues.removeAll()
        lowValues.removeAll()
        closeValues.removeAll()
        openValues.removeAll()
    }
    
    
    //MARK: - Tableview delegates and datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.staticTimeIntervals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoTVC", for: indexPath) as! CryptoTVC
        cell.cryptoNameLabel.text = self.staticTimeIntervals[indexPath.row].text
        if #available(iOS 13.0, *) {
            cell.selectedImageView.image = self.initalSelection[indexPath.row] ? UIImage(systemName: "checkmark.diamond.fill") : UIImage(systemName: "")
        } else {
            // Fallback on earlier versions
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.initalSelection[indexPath.row] == false && self.initalSelection.contains(where: {$0 == true}){
            self.initalSelection.removeAll()
            for _ in 0..<self.staticTimeIntervals.count {
                self.initalSelection.append(false)
            }
            self.initalSelection[indexPath.row] = !(self.initalSelection[indexPath.row])
            self.isFirstTime = true
        } else if self.initalSelection[indexPath.row] == true {
            print("Can't allow")
        }
        else {
            self.initalSelection[indexPath.row] = !(self.initalSelection[indexPath.row])
            self.isFirstTime = true
        }
        self.chartTitlleLabel.text = "\(self.staticTimeIntervals[indexPath.row].text)"
        selectedInterval = self.staticTimeIntervals[indexPath.row]
        if !isFirstTime {
            self.disconnectRequest()
        }
        getTimelineData()
        candleStickChartView.notifyDataSetChanged()
        self.timeIntervalTV.isHidden = true
        self.dropDownImage.transform = CGAffineTransform(rotationAngle: .pi)
    }
    //MARK: - API functions
    func getTimelineData() {
        let interval = selectedInterval?.description ?? Interval.oneday.description
        Alamofire.request("https://api.binance.com/api/v3/klines?symbol=\(selectedCoinPair)&interval=\(interval)&limit=500").responseData(queue: nil, completionHandler: { [self]response in
            switch response.result {
                
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    self.timelineDataModel = try decoder.decode(TimelineAPIDataModel.self, from: data)
                    self.removeAllValues()
                    for i in 0..<self.timelineDataModel.count {
                        xValues.append(self.timelineDataModel[i][0].DoubleValue)
                        openValues.append(self.timelineDataModel[i][1].DoubleValue)
                        highValues.append(self.timelineDataModel[i][2].DoubleValue)
                        lowValues.append(self.timelineDataModel[i][3].DoubleValue)
                        closeValues.append(self.timelineDataModel[i][4].DoubleValue)
                        volumeValues.append(self.timelineDataModel[i][5].DoubleValue)
                        closeTime.append(self.timelineDataModel[i][6].DoubleValue)
                    }
                    self.makeRequest()
                    self.makePriceRequest()
    //                self.calculateMA(7)
                    //                self.customizeChart(x: self.xValues, high: self.highValues, low: self.lowValues, open: self.openValues, close: self.closeValues)
                    
                    self.customizeChart()
                    self.customizeLineChart()
                    self.setCombinedChart()
                    self.customizeBarChart()
                    self.setCombinedCV2()
                } catch {
                    
                }
            case .failure(let error):
                print(error)
            }
        })

    }
    
    
    //MARK: - Chart functions
    func interval(fromStart start: Date,
                  toEnd end: Date,
                  component: Calendar.Component,
                  value: Interval) -> [Date] {
        var result = [Date]()
        var working = start
        repeat {
            result.append(working)
            guard let new = Calendar.current.date(byAdding: component, value: value.intervalValue , to: working) else { return result }
            working = new
        } while working <= end
        return result
    }
    
    func intervalString(dates: [Date], intervalType :Interval)-> [String]{
        var intervalDates = [String]()
        for i in 0..<dates.count {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YY/MM/dd"
            intervalDates.append(dateFormatter.string(from: dates[i]))
        }
        return intervalDates
    }
    func dateToString(date : NSDate) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY/MM/dd"
        return dateFormatter.string(from: date as Date)
    }

    
    func customizeChart () {
//        candleStickChartView.clearValues()
        candleStickChartView.notifyDataSetChanged()
        var candleChartEntry = [CandleChartDataEntry]()
        for index in 0..<xValues.count {
            let histoValue = CandleChartDataEntry.init(x: Double(index), shadowH: highValues[index], shadowL: lowValues[index], open: openValues[index], close: closeValues[index])
            candleChartEntry.append(histoValue)
        }
        let candle1 = CandleChartDataSet(entries: candleChartEntry, label: "")
        candle1.axisDependency = .left
        candle1.setColor(UIColor(white: 80 / 255.0, alpha: 1.0))
        candle1.drawIconsEnabled = false
        candle1.shadowColor = NSUIColor.darkGray
        candle1.shadowWidth = 1.5
        candle1.decreasingColor = NSUIColor.red
        candle1.decreasingFilled = true
        candle1.increasingColor = NSUIColor(red: 122 / 255.0, green: 242 / 255.0, blue: 84 / 255.0, alpha: 1.0)
        candle1.increasingFilled = true
        candle1.showCandleBar = true
        candle1.neutralColor = NSUIColor.blue
        candle1.drawValuesEnabled = true
        candle1.shadowColorSameAsCandle = true

        
   
        //        candleStickChartView.xAxis.wordWrapEnabled = true
        let candleData = CandleChartData(dataSets: [candle1])
        self.candleStickChartView.data = candleData
        self.setupMarkerView()
        self.intervalTimeStampCases(xAxis: candleStickChartView.xAxis)
        candleStickChartView.legend.enabled = false
//        candleStickChartView.autoScaleMinMaxEnabled = true
        candleStickChartView.dragEnabled = true
        candleStickChartView.doubleTapToZoomEnabled = false
//        candleStickChartView.drawMarkers = true
        

//        print("Scale X :",candleStickChartView.scaleX)
        candleStickChartView.delegate = self

        candleStickChartView.setVisibleXRange(minXRange: 1, maxXRange: 50)
        candleStickChartView.clipValuesToContentEnabled = true
        candleStickChartView.scaleYEnabled = false
        candleStickChartView.pinchZoomEnabled = true
        candleStickChartView.setDragOffsetX(20)
        candleStickChartView.leftAxis.drawAxisLineEnabled = false
        candleStickChartView.leftAxis.drawLabelsEnabled = false
//        guard let price = priceModel.price.toDouble() else {return}
//        let limit = ChartLimitLine(limit: price, label: "Current Price = \(priceModel.price.toDouble()?.removeZerosFromEnd() ?? "")")
//        limit.lineColor = .yellow
//        limit.labelPosition  = .leftTop
//        if candleStickChartView.rightAxis.limitLines.isEmpty {
//            candleStickChartView.rightAxis.addLimitLine(limit)
//        } else {
//            candleStickChartView.rightAxis.removeAllLimitLines()
//            candleStickChartView.rightAxis.addLimitLine(limit)
//        }
        candleStickChartView.renderer = MyCandleStickChartRenderer(view: self.candleStickChartView)
    }
    
    
    func customizeLineChart() {
        lineChartView.clearValues()
        var lineChartEntries = [ChartDataEntry]()
        for index in 0..<xValues.count {
            let histo = ChartDataEntry.init(x: Double(index), y: closeValues[index])
            lineChartEntries.append(histo)
        }
        let lineDataSet = LineChartDataSet.init(entries: lineChartEntries, label: "")
        lineDataSet.drawCirclesEnabled = false
        lineDataSet.colors = [.green]
        let gradientColors = [UIColor.green.cgColor, UIColor.black.cgColor] as CFArray // Colors of the gradient
        let colorLocations:[CGFloat] = [1.0, 0.0] // Positioning of the gradient
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        lineDataSet.fill = LinearGradientFill(gradient: gradient!, angle: 90) // Set the Gradient
        lineDataSet.drawFilledEnabled = true
        lineDataSet.drawValuesEnabled = false
        lineDataSet.mode = .linear
       
        let lineChartData = LineChartData(dataSets:[lineDataSet])
        self.lineChartView.data = lineChartData
        self.lineChartView.marker = self.markerView
        self.lineChartView.delegate = self
        lineChartView.legend.enabled = false
        lineChartView.autoScaleMinMaxEnabled = true
        lineChartView.dragEnabled = true
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.drawMarkers = true
        lineChartView.scaleYEnabled = false
        lineChartView.highlightPerTapEnabled = true
        lineChartView.setVisibleXRange(minXRange: 1, maxXRange: 50)
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.viewPortHandler.setDragOffsetX(20)

        lineChartView.xAxis.setLabelCount(4, force: false)
        self.intervalTimeStampCases(xAxis: lineChartView.xAxis)
        guard let price = priceModel.price.toDouble() else {return}
        let limit = ChartLimitLine(limit: price, label: "Current Price = \(priceModel.price.toDouble()?.removeZerosFromEnd() ?? "")")
        limit.lineColor = .yellow
        limit.labelPosition  = .leftTop
        if lineChartView.rightAxis.limitLines.isEmpty {
            lineChartView.rightAxis.addLimitLine(limit)
        } else {
            lineChartView.rightAxis.removeAllLimitLines()
            lineChartView.rightAxis.addLimitLine(limit)
        }
    }
    
    func customizeBarChart(){
        barChartView.notifyDataSetChanged()
        var barChartEntries = [BarChartDataEntry]()
        var colors = [UIColor]()
        for index in 0..<xValues.count {
            let histo = BarChartDataEntry.init(x: Double(index), y: volumeValues[index])
            barChartEntries.append(histo)
            if  openValues[index] > closeValues[index] {
                colors.append(.red)
            }else {
                colors.append(.green)
            }
            
        }
        
        let barChartDataSet = BarChartDataSet.init(entries: barChartEntries, label: "")
        barChartDataSet.colors = colors

        let barChartData = BarChartData.init(dataSets: [barChartDataSet])
        barChartData.setDrawValues(false)
        barChartView.data = barChartData
        barChartView.legend.enabled = false
        barChartView.delegate = self
        barChartView.doubleTapToZoomEnabled = false
        barChartView.scaleYEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.scaleXEnabled = false
        barChartView.setDragOffsetX(20)
        barChartView.dragEnabled = true

        barChartView.xAxis.labelPosition = .bottom
//        barChartView.autoScaleMinMaxEnabled = true
        barChartView.setVisibleXRange(minXRange: 1, maxXRange: 50)
        barChartView.clipDataToContentEnabled = true

        barChartView.xAxis.granularity = 1.0
        barChartView.leftAxis.granularity = 1.0
        if barChartView.highestVisibleX >= xValues[xValues.count - 25] {
            self.moveToLastX()
        }
        intervalTimeStampCases(xAxis: barChartView.xAxis)

    }
    
    func customizeCombinedChart() {
        combineGraphView.notifyDataSetChanged()
        var candleChartEntries = [CandleChartDataEntry]()
        for index in 0..<xValues.count {
            let histo1 = CandleChartDataEntry.init(x: Double(index), shadowH: highValues[index], shadowL: lowValues[index], open: openValues[index], close: closeValues[index])
            candleChartEntries.append(histo1)
        }

        
        var ma7 = [ChartDataEntry]()
        self.movingAverageFor7 = self.calculateEMA(7)
        for index in 0..<xValues.count {
            let ma = ChartDataEntry.init(x: Double(index), y: self.movingAverageFor7[index])
            ma7.append(ma)
        }
        
        var ma25 = [ChartDataEntry]()
        let movingAverageFor25 = self.calculateEMA(25)
        for index in 0..<xValues.count {
            let ma = ChartDataEntry.init(x: Double(index), y: movingAverageFor25[index])
            ma25.append(ma)
        }
        
        var ma99 = [ChartDataEntry]()
        let movingAverageFor99 = self.calculateEMA(99)
        for index in 0..<xValues.count {
            let ma = ChartDataEntry.init(x: Double(index), y: movingAverageFor99[index])
            ma99.append(ma)
        }

        let ema12 = self.calculateEMA(12)
        let ema26 = self.calculateEMA(26)
        var MACD = [Double]()
        for i in 0..<ema12.count {
            MACD.append(ema12[i] - ema26[i])
        }
        
        var MACDEntries = [ChartDataEntry]()
        for index in 0..<xValues.count {
            let histo = ChartDataEntry.init(x: Double(index), y: MACD[index])
            MACDEntries.append(histo)
        }
        
        let candleDataSet = CandleChartDataSet.init(entries: candleChartEntries, label: "")
        candleDataSet.axisDependency = .left
        candleDataSet.setColor(UIColor(white: 80 / 255.0, alpha: 1.0))
        candleDataSet.drawIconsEnabled = false
        candleDataSet.shadowColor = NSUIColor.darkGray
        candleDataSet.shadowWidth = 1.5
        candleDataSet.decreasingColor = NSUIColor.red
        candleDataSet.decreasingFilled = true
        candleDataSet.increasingColor = NSUIColor(red: 122 / 255.0, green: 242 / 255.0, blue: 84 / 255.0, alpha: 1.0)
        candleDataSet.increasingFilled = true
        candleDataSet.showCandleBar = true
        candleDataSet.neutralColor = NSUIColor.blue
        candleDataSet.drawValuesEnabled = false
        candleDataSet.shadowColorSameAsCandle = true
        
        let lineDataSet = LineChartDataSet.init(entries: ma25, label: "")
        lineDataSet.drawCirclesEnabled = false
        lineDataSet.colors = [.purple]
        lineDataSet.mode = .linear
        lineDataSet.drawValuesEnabled = false
        lineDataSet.lineWidth = 3
        
        let lineDataSet2 = LineChartDataSet.init(entries: ma7, label: "")
        lineDataSet2.drawCirclesEnabled = false
        lineDataSet2.colors = [.brown]
        lineDataSet2.mode = .linear
        lineDataSet2.drawValuesEnabled = false
        lineDataSet2.lineWidth = 3
        
        let lineDataSet3 = LineChartDataSet.init(entries: ma99, label: "")
        lineDataSet3.drawCirclesEnabled = false
        lineDataSet3.colors = [.cyan]
        lineDataSet3.mode = .linear
        lineDataSet3.drawValuesEnabled = false
        lineDataSet3.lineWidth = 3
  
        
        let combineChartData = CombinedChartData()
//        combineChartData.lineData = LineChartData.init(dataSets: [lineDataSet2,lineDataSet,lineDataSet3])
        combineChartData.candleData = CandleChartData.init(dataSets: [candleDataSet])
        self.combineGraphView.data = combineChartData
        combineGraphView.legend.enabled = false
        combineGraphView.delegate = self
        combineGraphView.dragEnabled = true
        combineGraphView.doubleTapToZoomEnabled = false

        combineGraphView.scaleYEnabled = false

        combineGraphView.viewPortHandler.setDragOffsetX(20)
        combineGraphView.autoScaleMinMaxEnabled = true
        combineGraphView.setVisibleXRange(minXRange: 1, maxXRange: 50)
        if combineGraphView.highestVisibleX >= xValues[xValues.count - 25] {
            self.moveToLastX()
        }

        combineGraphView.xAxis.granularity = 1.0
        combineGraphView.leftAxis.granularity = 1.0
        self.intervalTimeStampCases(xAxis: combineGraphView.xAxis)

        
    }
    func setCombinedChart() {
        let ema12 = indicatorEMA(yValues: closeValues, period: 12)
        let ema26 = indicatorEMA(yValues: closeValues, period: 26)
        var MACD = [Double]()
        for i in 0..<ema26.count {
            MACD.append(ema12[i] - ema26[i])
        }
        let signal = indicatorEMA(yValues: MACD, period: 9)
        var histogram = [Double]()
        for i in 0..<signal.count {
            histogram.append(MACD[i] - signal[i])
        }
        //Bar Chart
        var barEntries = [BarChartDataEntry]()
        var colors = [UIColor]()
        for i in 0..<MACD.count {
            let histo = BarChartDataEntry.init(x: Double(i), y: MACD[i])
            barEntries.append(histo)
            if MACD[i] <= 0 {
                colors.append(.red)
            }else {
                colors.append(.green)
            }
        }
        
        let barChartDataSet = BarChartDataSet.init(entries: barEntries, label: "")
        barChartDataSet.colors = colors

        let combineChartData = CombinedChartData()
        let barChartData = BarChartData.init(dataSets: [barChartDataSet])
        barChartData.setDrawValues(false)
//        combineChartData.barData = barChartData

//        Line Chart
        var signalLineEntries = [ChartDataEntry]()
        for i in 0..<signal.count {
            let line = ChartDataEntry(x: Double(i), y: signal[i])
            signalLineEntries.append(line)
            
        }
        
        var histogramLineEntries = [ChartDataEntry]()
        for i in 0..<histogram.count {
            let line = ChartDataEntry.init(x: Double(i), y: histogram[i])
            histogramLineEntries.append(line)
        }

        let signalLineDataSet = LineChartDataSet.init(entries: signalLineEntries, label: "")
        signalLineDataSet.drawValuesEnabled = false
        signalLineDataSet.drawCirclesEnabled = false
        signalLineDataSet.mode = .linear
        signalLineDataSet.lineWidth = 2
        signalLineDataSet.colors = [.purple]
        
        let histogramLineDataSet = LineChartDataSet.init(entries: histogramLineEntries, label: "")
        histogramLineDataSet.drawValuesEnabled = false
        histogramLineDataSet.drawCirclesEnabled = false
        histogramLineDataSet.mode = .linear
        histogramLineDataSet.lineWidth = 2
        histogramLineDataSet.colors = [.cyan]
        
        let lineData = LineChartData.init(dataSets: [signalLineDataSet,histogramLineDataSet])
        combineChartData.barData = barChartData
        combineChartData.lineData = lineData
        combineGraphView.data = combineChartData
        combineGraphView.legend.enabled = false
        combineGraphView.delegate = self
        combineGraphView.doubleTapToZoomEnabled = false
        combineGraphView.scaleYEnabled = false
        combineGraphView.pinchZoomEnabled = false
        combineGraphView.setDragOffsetX(20)
        combineGraphView.dragEnabled = true
        combineGraphView.xAxis.labelPosition = .bottom
        combineGraphView.autoScaleMinMaxEnabled = true
        combineGraphView.clipDataToContentEnabled = true
        combineGraphView.setVisibleXRange(minXRange: 1, maxXRange: 50)
        intervalTimeStampCases(xAxis: combineGraphView.xAxis)
    }
    
    
    func setCombinedCV2() {
//        var TP = [Double]()
//        var TP20 = Double()
//        var average = Double()
        
//        for _ in 0..<20 {
//            average = 0.0
//            TP.append(average)
//        }
//        for i in 0..<xValues.count - 20 {
//            for j in stride(from: i, to: (i+20), by: 1) {
//                average += closeValues[j]
//            }
//            TP.append(average/20)
//            average = 0.0
//        }
//        for i in 0..<xValues.count {
//            TP.append((closeValues[i] + lowValues[i] + highValues[i])/3)
//        }
        let a = calculateMA(values: closeValues, forInterval: 20)
        let b = (2*getStandardDeviation(values: closeValues, mean: 20))
        
        var BOLU = [Double]()
        for i in 0..<a.count {
            BOLU.append(a[i]+b)
        }
        
        var BOLD = [Double]()
        for i in 0..<a.count {
            BOLD.append(a[i]-b)
        }
        
        let BOLM = calculateMA(values: closeValues, forInterval: 20)
        
        var BOLUDataEntries = [ChartDataEntry]()
        for i in 0..<BOLU.count {
            let histo = ChartDataEntry(x: Double(i), y: BOLU[i])
            BOLUDataEntries.append(histo)
        }
        
        var BOLDDataEntries = [ChartDataEntry]()
        for i in 0..<BOLD.count {
            let histo = ChartDataEntry(x: Double(i), y: BOLD[i])
            BOLDDataEntries.append(histo)
        }
        
        var BOLMDataEntries = [ChartDataEntry]()
        for i in 0..<BOLM.count {
            let histo = ChartDataEntry(x: Double(i), y: BOLM[i])
            BOLMDataEntries.append(histo)
        }
        
        
        let BOLUDataSets = LineChartDataSet(entries: BOLUDataEntries, label: "")
        BOLUDataSets.drawCirclesEnabled = false
        BOLUDataSets.colors = [.purple]
        BOLUDataSets.mode = .linear
        BOLUDataSets.drawValuesEnabled = false
        BOLUDataSets.lineWidth = 3
        
        let BOLDDataSets = LineChartDataSet(entries: BOLDDataEntries, label: "")
        BOLDDataSets.drawCirclesEnabled = false
        BOLDDataSets.colors = [.orange]
        BOLDDataSets.mode = .linear
        BOLDDataSets.drawValuesEnabled = false
        BOLDDataSets.lineWidth = 3
        
        let BOLMDataSets = LineChartDataSet(entries: BOLMDataEntries, label: "")
        BOLMDataSets.drawCirclesEnabled = false
        BOLMDataSets.colors = [.blue]
        BOLMDataSets.mode = .linear
        BOLMDataSets.drawValuesEnabled = false
        BOLMDataSets.lineWidth = 3
        
        let lineData = LineChartData(dataSets: [BOLUDataSets,BOLDDataSets,BOLMDataSets])
        let combineChartData = CombinedChartData()
        combineChartData.lineData = lineData
        combinedCV2.data = combineChartData
        combinedCV2.legend.enabled = false
        combinedCV2.delegate = self
        combinedCV2.doubleTapToZoomEnabled = false
        combinedCV2.scaleYEnabled = false
        combinedCV2.pinchZoomEnabled = false
        combinedCV2.setDragOffsetX(20)
        combinedCV2.dragEnabled = true
        combinedCV2.xAxis.labelPosition = .bottom
        combinedCV2.autoScaleMinMaxEnabled = true
        combinedCV2.clipDataToContentEnabled = true
        combinedCV2.setVisibleXRange(minXRange: 1, maxXRange: 50)
        intervalTimeStampCases(xAxis: combinedCV2.xAxis)
        
        
//        BOLU=MA(TP,n)+m∗σ[TP,n]
//        BOLD=MA(TP,n)−m∗σ[TP,n]
//        where:
//        BOLU=Upper Bollinger Band
//        BOLD=Lower Bollinger Band
//        MA=Moving average
//        TP (typical price)=(High+Low+Close)÷3
//        n=Number of days in smoothing period (typically 20)
//        m=Number of standard deviations (typically 2)
//        σ[TP,n]=Standard Deviation over last n periods of TP
    }
    
    
    
    //MARK: - Calculations and Other functions

    func indicatorEMA(yValues: [Double], period: Int=20) -> [Double]{
        var sum = 0.0
        var EMA: [Double] = []
        let multiplier:Double = Double((period+1))
        //Estimate Moving average
        for i in 0..<Int(period) {
            sum  += yValues[i]
            if i < Int(period)-1 {
                EMA.append(0)//These values are to be ignored
            }
        }
        EMA.append(sum/Double(period))
        for i in Int(period)..<yValues.count {
            let ema = (yValues[i] * (2/multiplier)) + ((EMA.last ?? 0.0) * (1-(2/multiplier)))
            EMA.append(ema)
        }
        return EMA
    }

    func calculateEMA(_ forInterval : Int) -> [Double] {
        let initialValue = closeValues.reduce(.zero , +)
        var EMAY = initialValue/Double(closeValues.count)
        var EMAT = 0.0
        let smoothing = 2/(forInterval+1)
        var arrayEMA = [Double]()
        for i in 0..<closeValues.count {
            let a = Double(closeValues[i] * Double((smoothing/1+forInterval)))
            let b = Double(EMAY*Double((1-(smoothing/1+forInterval))))
            EMAT = a + b
            arrayEMA.append(EMAT)
            EMAY = EMAT
        }
        return arrayEMA
        
    }
    
    func getStandardDeviation(values : [Double], mean : Double) -> Double {
        let mapValue = values.map{
                return pow(Double($0) - mean,2)
            }.reduce(0.0) { a, b in
                a + b
            }
            let value  = sqrt(mapValue/Double(values.count))
            return value
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        if  chartView == self.combineGraphView {
            let currentMatrix = chartView.viewPortHandler.touchMatrix
            DispatchQueue.main.async { [self] in
                self.barChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: self.barChartView, invalidate: false)
                self.lineChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: lineChartView, invalidate: false)
                self.candleStickChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: candleStickChartView, invalidate: false)
            }
        }else if chartView == self.barChartView{
                   let currentMatrix = chartView.viewPortHandler.touchMatrix
                   DispatchQueue.main.async { [self] in
                       self.lineChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: lineChartView, invalidate: false)
                       self.combineGraphView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: self.combineGraphView, invalidate: false)
                       self.candleStickChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: candleStickChartView, invalidate: false)
                   }
        } else if chartView == self.candleStickChartView {
            let currentMatrix = chartView.viewPortHandler.touchMatrix
            DispatchQueue.main.async { [self] in
                self.lineChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: lineChartView, invalidate: false)
                self.combineGraphView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: self.combineGraphView, invalidate: false)
                self.barChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: barChartView, invalidate: false)
            }
        }  else  {
            let currentMatrix = chartView.viewPortHandler.touchMatrix
            DispatchQueue.main.async { [self] in
                self.candleStickChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: candleStickChartView, invalidate: false)
                self.combineGraphView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: self.combineGraphView, invalidate: false)
                self.barChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: barChartView, invalidate: false)
            }
        }
    }
    
    
    
    func checkLast() {
        if  self.barChartView.highestVisibleX >= (self.barChartView.chartXMax - 5) || self.combineGraphView.highestVisibleX >= (self.combineGraphView.chartXMax - 5) {
            moveToLastX()
        }
//        if self.barChartV
        
//            .iew.highestVisibleX == self.barChartView.chartXMax || self.combineGraphView.highestVisibleX == self.combineGraphView.chartXMax {
//            print("Do nothing")
//        } else
//        self.candleStickChartView.highestVisibleX >= (self.candleStickChartView.chartXMax - 25) || self.lineChartView.highestVisibleX >= (self.lineChartView.chartXMax - 25) ||
    }
    func moveToLastX () {
       
//        combineGraphView.setVisibleXRangeMaximum(30)
//        candleStickChartView.setVisibleXRangeMaximum(30)
//        lineChartView.setVisibleXRangeMaximum(30)
        let lastX = combineGraphView.chartXMax
        combineGraphView.moveViewToX(lastX)
        candleStickChartView.moveViewToX(lastX)
        lineChartView.moveViewToX(lastX)
        barChartView.moveViewToX(lastX)
    }
    func calculateMA(_ forInterval : Int) -> [Double]{

        var average = 0.0
        var arrayOfMA = [Double]()
        for index in 0..<forInterval {
            average = closeValues[index]
            arrayOfMA.append(average)
            average = 0.0
        }
        for i in 0..<closeValues.count - forInterval {
            for j in stride(from: i, to: (i+forInterval), by: 1) {
                average += closeValues[j]
            }
            average = average/Double(forInterval)
            arrayOfMA.append(average)
            average = 0.0
        }
        print(arrayOfMA)
        print(arrayOfMA.count)
        return arrayOfMA
        
        
    }
    
    func calculateMA(values : [Double], forInterval : Int) -> [Double] {
        var average = 0.0
        var arrayOfMA = [Double]()
//        for _ in 0..<forInterval {
////            average = values[index]
//            arrayOfMA.append(average)
//        }
        for i in 0..<values.count - forInterval{
            for j in stride(from: (i+forInterval), to: i , by: -1) {
                average += values[j]
            }
            average = average/Double(forInterval)
            arrayOfMA.append(average)
            average = 0.0
        }
//        print(arrayOfMA)
//        print(arrayOfMA.count)
        return arrayOfMA
    }
    
    func setupMarkerView() {
        self.markerView.chartView = self.candleStickChartView
        self.candleStickChartView.marker = self.markerView
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let dataSet = chartView.data?.dataSets[highlight.dataSetIndex] else { return }
        let entryIndex = dataSet.entryIndex(entry: entry)
        if openValues[entryIndex] <= closeValues[entryIndex] {
            markerView.greenTextColour()
        } else {
            markerView.redTextColour()
        }
        
        markerView.openLabel.text = "Open: "+openValues[entryIndex].description
        markerView.closeLabel.text = "Close: "+closeValues[entryIndex].description
        markerView.highLabel.text = "High: "+highValues[entryIndex].description
        markerView.lowLabel.text = "Low: "+lowValues[entryIndex].description
        let time = markerTimeStampCases(closeTime[entryIndex])
        markerView.timeLabel.text = "Time: "+time
    }
    
    
     func intervalTimeStampCases (xAxis : XAxis ) {
        let interval = selectedInterval ?? .oneday
        switch interval {
        case .onemin:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .threemin:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .fivemin:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .fifteenmin:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .thirthymin:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .onehour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .twohour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .fourhour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .sixhour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .eighthour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .twelevehour:
            xAxis.valueFormatter = ChartFormatterTime(timeSamps: xValues)
        case .oneday:
            xAxis.valueFormatter = ChartFormatter(timeStamps: xValues)
        case .threeday:
            xAxis.valueFormatter = ChartFormatter(timeStamps: xValues)
        case .oneweek:
            xAxis.valueFormatter = ChartFormatter(timeStamps: xValues)
        case .onemonth:
            xAxis.valueFormatter = ChartFormatter(timeStamps: xValues)
        }
    }
    
    func markerTimeStampCases (_ forTime : Double) -> String {
        let interval = selectedInterval ?? .oneday
        switch interval {
        case .onemin:
            return dateFormatterForTime(forTime: forTime)
        case .threemin:
            return dateFormatterForTime(forTime: forTime)
        case .fivemin:
            return dateFormatterForTime(forTime: forTime)
        case .fifteenmin:
            return dateFormatterForTime(forTime: forTime)
        case .thirthymin:
            return dateFormatterForTime(forTime: forTime)
        case .onehour:
            return dateFormatterForTime(forTime: forTime)
        case .twohour:
            return dateFormatterForTime(forTime: forTime)
        case .fourhour:
            return dateFormatterForTime(forTime: forTime)
        case .sixhour:
            return dateFormatterForTime(forTime: forTime)
        case .eighthour:
            return dateFormatterForTime(forTime: forTime)
        case .twelevehour:
            return dateFormatterForTime(forTime: forTime)
        case .oneday:
            return dateFormatterForDay(forTime: forTime)
        case .threeday:
            return dateFormatterForDay(forTime: forTime)
        case .oneweek:
            return dateFormatterForDay(forTime: forTime)
        case .onemonth:
            return dateFormatterForDay(forTime: forTime)
        }
    }
    
    func dateFormatterForTime(forTime : Double) -> String{
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm"
        let timeSnap = forTime
        let date = Date(timeIntervalSince1970: timeSnap/1000)
        let time = dateFormatterPrint.string(from: date)
        return time
    }
    func dateFormatterForDay(forTime : Double) -> String{
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd/MM/YY"
        let timeSnap = forTime
        let date = Date(timeIntervalSince1970: timeSnap/1000)
        let time = dateFormatterPrint.string(from: date)
        return time
    }
    
}



//MARK: - Chart formatter 
final class ChartFormatter : AxisValueFormatter {
    var timeStamps = [Double]()
    init (timeStamps : [Double]) {
        self.timeStamps = timeStamps
    }
    
    
    enum CustomLabel: Int {
        case firstLabel
        
        var label: String {
            switch self {
            case .firstLabel: return ""
            }
        }
    }
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd/MM/YY"
        let index = Int(value)
        if  index >= 0 && index < timeStamps.count{
        let timeSnap = timeStamps[index]
        let date = Date(timeIntervalSince1970: timeSnap/1000)
        let time = dateFormatterPrint.string(from: date)

        return  "\(time)"
        } else {
            return ""
        }
    }
    
    
}
final class ChartFormatterTime : AxisValueFormatter {
    var timeStamps = [Double]()
    init(timeSamps: [Double]) {
        self.timeStamps = timeSamps
    }
    
    
    
    enum CustomLabel: Int {
        case firstLabel
        
        var label: String {
            switch self {
            case .firstLabel: return ""
            }
        }
    }
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm a"
        let index = Int(value)
        if  index >= 0 && index < timeStamps.count{
        let timeSnap = timeStamps[index]
        let date = Date(timeIntervalSince1970: timeSnap/1000)
        let time = dateFormatterPrint.string(from: date)
        return "\(time)"
        } else {
            return ""
        }
    }
    
    
}

