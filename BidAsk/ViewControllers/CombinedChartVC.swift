//
//  CombinedChartVC.swift
//  BidAsk
//
//  Created by admin on 3/18/22.
//

import Foundation
import UIKit
import Charts
import Starscream
import Alamofire

class CombinedChartVC : UIViewController, WebSocketDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    //MARK: - Outlets
    
    @IBOutlet weak var combinedCV: CombinedChartView!
    
    @IBOutlet weak var candleStickCV: CandleStickChartView!
    
    @IBOutlet weak var tableViewHV: UIView!
    
    @IBOutlet weak var typesOfChartsTV: UITableView!
    
    @IBOutlet weak var chartViewHV: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var topHV: UIView!
    
    @IBOutlet weak var imageViewHV: UIView!
    @IBOutlet weak var drawImageView: UIImageView!
    //MARK: - Local Variables
    var socket : WebSocket!
    var isFirstTime = true
    var currentTimeStamp = Double()
    var lastTimeStamp = Double()
    var updatedDataModel = TimelineDataModel()
    var timelineDataModel = TimelineAPIDataModel()
    var lowValues = [Double]()
    var closeTime = [Double]()
    var closeValues = [Double]()
    var openValues = [Double]()
    var highValues = [Double]()
    var volumeValues = [Double]()
    let charts = [Charts.HeikenAshi,Charts.BullAverageDirectionalIndex,Charts.Aroon,Charts.ATR,Charts.CCI,Charts.ChandlerExit,Charts.DetrendedPriceOscillator,Charts.AvgOfHighLow,Charts.IchimokuCloud,Charts.Kaufmans,Charts.KDJOscillator, Charts.MoneyFlowIndicator, Charts.OBV, Charts.PriceChannel, Charts.PSAR, Charts.RSI, Charts.VolumeWeightedAverage, Charts.TRIX, Charts.SuperTrendDown, Charts.BullishStochValues, Charts.TrendContinuationFactor, Charts.PivotHighLow, Charts.Keltner,Charts.MACD,Charts.BollinderBands]
    var filteredChart = [Charts]()
    var selectedChart = Charts.HeikenAshi
    var isFiltering = false
    
    //MARK: - Class functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Different Types of Charts"
        getTimelineData()
        self.typesOfChartsTV.delegate = self
        self.typesOfChartsTV.dataSource = self
        self.searchBar.delegate = self
        self.tableViewHV.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction(_:)))
        self.imageViewHV.addGestureRecognizer(tap)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let socket = self.socket,!isFirstTime {
            socket.disconnect()
        }
    }
    
    //MARK: - Tap Gesture
    @objc func tapFunction(_ sender : UITapGestureRecognizer?) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.isOpaque, 0.0)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageData: NSData = (image!.jpegData(compressionQuality: 1.0) as NSData?)!
        imageData.write(toFile: "image1.jpeg", atomically: true)
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "DrawImageViewController") as! DrawImageViewController
//        vc.newImage = image ?? UIImage()
//        self.navigationController?.pushViewController(vc, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CustomDrawingViewController") as! CustomDrawingViewController
        vc.image = image ?? UIImage()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Tableview functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredChart.count : charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TypesOfChartTVC", for: indexPath) as! TypesOfChartTVC
        cell.chartStyleLabel.text = isFiltering ? filteredChart[indexPath.row].stringValue : charts[indexPath.row].stringValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedChart = isFiltering ? filteredChart[indexPath.row] : charts[indexPath.row]
        self.tableViewHV.isHidden = true
        self.searchBar.text = isFiltering ? filteredChart[indexPath.row].stringValue : charts[indexPath.row].stringValue
        self.title = isFiltering ? filteredChart[indexPath.row].stringValue : charts[indexPath.row].stringValue
        self.view.endEditing(true)
        self.getTimelineData()
    }
    
    //MARK: - Searchbar functions
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.updateChartStyle(searchText)
    }
    func updateChartStyle(_ searchText : String) {
        if searchText.isEmpty {
            filteredChart.removeAll()
            isFiltering = false
            self.tableViewHV.isHidden = true
        } else {
            filteredChart = charts.filter{$0.stringValue.range(of: searchText, options: .caseInsensitive) != nil }
            isFiltering = true
            self.tableViewHV.isHidden = false
            searchBar.returnKeyType = .done
        }
        typesOfChartsTV.reloadData()
    }
    
    //MARK: - API Function
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
                    self.updateValues()
                    //                    self.setCombinedChart()
                    self.changeChartStyle()
                    
                } catch {
                    
                }
            case .failure(let error):
                print(error)
            }
        })
        
    }
    
    func changeChartStyle() {
        switch self.selectedChart {
        case .HeikenAshi:
            self.setupHeikenAshi()
            self.candleStickCV.isHidden = false
            self.combinedCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .BullAverageDirectionalIndex:
            self.setupBullDirectionalIndexChart()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .Aroon:
            self.setupAroonIndicator()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .ATR:
            self.setupATR()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .ChandlerExit:
            self.setupChandlerExit()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .CCI:
            self.setupCCI()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .DetrendedPriceOscillator:
            self.setupDetrendedPriceOscillator()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .AvgOfHighLow:
            self.setupAvgHighLow()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .IchimokuCloud:
            self.setupIchimokuCloud()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .Kaufmans:
            self.setupKaufmans()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .KDJOscillator:
            self.setupKDJOscillator()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .MoneyFlowIndicator:
            self.setupMoneyFlowIndex()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .OBV:
            self.setupOBV()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .PriceChannel:
            self.setupPriceChannel()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .PSAR:
            self.setupPSAR()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .RSI:
            self.setupRSI()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .VolumeWeightedAverage:
            self.setupVolumeWeightedAveragePrice()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .TRIX:
            self.setupTRIXIndicator()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .TrendContinuationFactor:
            self.setupTrendContinuationFactorPOS()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .SuperTrendDown:
            self.setupSuperTrendDown()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .BullishStochValues:
            self.setupBullishStochValues()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .PivotHighLow:
            self.setupPivotHighLow()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .Keltner:
            self.setupKeltnerChannel()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .MACD:
            self.setupMACD()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        case .BollinderBands:
            self.setupBollingerBands()
            self.combinedCV.isHidden = false
            self.candleStickCV.isHidden = true
            self.chartViewHV.isHidden = false
        }
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
    
    //MARK: - Websocket functions
    func updateValues() {
        let interval = selectedInterval?.description ?? Interval.oneday.description
        let urlString = "wss://stream.binance.com:9443/ws/\(selectedCoinPair.lowercased())@kline_\(interval)"
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
        self.socket.connect()
    }
 
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let dictionary):
            print(dictionary)
        case .disconnected(let string, _):
            print(string)
        case .text(let string):
            let decoder = JSONDecoder()
            
            do {
                self.updatedDataModel = try decoder.decode(TimelineDataModel.self, from: string.data(using: .utf8)!)
                self.currentTimeStamp = (updatedDataModel.timeline.startTime.description.toDouble()?.truncate(places: 6))!
                if isFirstTime {
                    self.isFirstTime = false
                    self.lastTimeStamp = xValues.last ?? 0.0
                    self.changeChartStyle()
                }  else if self.currentTimeStamp == self.lastTimeStamp {
                    openValues[openValues.count - 1] = (updatedDataModel.timeline.open.description.toDouble()?.truncate(places: 6))!
                    closeValues[closeValues.count - 1] = (updatedDataModel.timeline.close.description.toDouble()?.truncate(places: 6))!
                    highValues[highValues.count - 1] = (updatedDataModel.timeline.high.description.toDouble()?.truncate(places: 6))!
                    lowValues[lowValues.count - 1] = (updatedDataModel.timeline.low.description.toDouble()?.truncate(places: 6))!
                    lastTimeStamp = (updatedDataModel.timeline.startTime.description.toDouble()?.truncate(places: 6))!
                    volumeValues[volumeValues.count - 1] = (updatedDataModel.timeline.volume.description.toDouble()?.truncate(places: 6))!
                    self.changeChartStyle()
                }
                else
                {
                    if self.currentTimeStamp > self.lastTimeStamp {
                        xValues.append(updatedDataModel.timeline.startTime.description.toDouble()!)
                        closeTime.append(updatedDataModel.timeline.close.description.toDouble()!)
                        openValues.append((updatedDataModel.timeline.open.description.toDouble()?.truncate(places: 6))!)
                        highValues.append((updatedDataModel.timeline.high.description.toDouble()?.truncate(places: 6))!)
                        lowValues.append((updatedDataModel.timeline.low.description.toDouble()?.truncate(places: 6))!)
                        closeValues.append((updatedDataModel.timeline.close.description.toDouble()?.truncate(places: 6))!)
                        volumeValues.append((updatedDataModel.timeline.volume.description.toDouble()?.truncate(places: 6))!)
                        self.lastTimeStamp = xValues.last ?? 0.0
                        self.changeChartStyle()
                    }
                }
            } catch {
                print(error)
            }
        case .binary(let data):
            print(data)
        case .pong(let optional):
            print(optional as Any)
        case .ping(let optional):
            print(optional as Any)
        case .error(let optional):
            print(optional as Any)
        case .viabilityChanged(let bool):
            print(bool)
        case .reconnectSuggested(let bool):
            print(bool)
        case .cancelled:
            print("Cancelled")
        }
    }
    
    //MARK: - Combined Chart Function
    
    func setupMACD() {
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
        combinedCV.data = combineChartData
        combinedCV.legend.enabled = false
        //        combinedCV.delegate = self
        combinedCV.doubleTapToZoomEnabled = false
        combinedCV.scaleYEnabled = false
        combinedCV.pinchZoomEnabled = false
        combinedCV.setDragOffsetX(20)
        combinedCV.dragEnabled = true
        combinedCV.xAxis.labelPosition = .bottom
        combinedCV.autoScaleMinMaxEnabled = true
        combinedCV.clipDataToContentEnabled = true
        combinedCV.setVisibleXRange(minXRange: 1, maxXRange: 50)
        intervalTimeStampCases(xAxis: combinedCV.xAxis)
    }
    
    //MARK: - Chart functions
    func setupHeikenAshi() {
        let heikenAshiValues = heikenAshiValues()
        var dataEntry = [CandleChartDataEntry]()
        for i in 0..<xValues.count {
            let histo = CandleChartDataEntry(x: Double(i), shadowH: heikenAshiValues[i]["high"] ?? 0.0, shadowL: heikenAshiValues[i]["low"] ?? 0.0, open: heikenAshiValues[i]["open"] ?? 0.0, close: heikenAshiValues[i]["close"] ?? 0.0)
            dataEntry.append(histo)
        }
        
        let dataSets = CandleChartDataSet(entries: dataEntry, label: "")
        dataSets.axisDependency = .left
        dataSets.setColor(UIColor(white: 80 / 255.0, alpha: 1.0))
        dataSets.drawIconsEnabled = false
        dataSets.shadowColor = NSUIColor.darkGray
        dataSets.shadowWidth = 1.5
        dataSets.decreasingColor = NSUIColor.red
        dataSets.decreasingFilled = true
        dataSets.increasingColor = NSUIColor(red: 122 / 255.0, green: 242 / 255.0, blue: 84 / 255.0, alpha: 1.0)
        dataSets.increasingFilled = true
        dataSets.showCandleBar = true
        dataSets.neutralColor = NSUIColor.blue
        dataSets.drawValuesEnabled = false
        dataSets.shadowColorSameAsCandle = true
        
        
        let data = CandleChartData(dataSets: [dataSets])
        candleStickCV.data = data
        
        candleStickCV.scaleYEnabled = false
        //        candleStickCV.autoScaleMinMaxEnabled = true
        candleStickCV.setVisibleXRange(minXRange: 1, maxXRange: 50)
        candleStickCV.legend.enabled = false
        candleStickCV.setDragOffsetX(20)
    }
    
    func setupBullDirectionalIndexChart() {
        let bullArray = bullDirectionalIndex()
        var dataEntry1 = [ChartDataEntry]()
        for i in 0..<closeValues.count - 1 {
            let histo = ChartDataEntry(x: Double(i), y: bullArray["adi"]![i])
            dataEntry1.append(histo)
        }
        
        var dataEntry2 = [ChartDataEntry]()
        for i in 0..<closeValues.count - 1{
            let histo = ChartDataEntry(x: Double(i), y: bullArray["upmove"]![i])
            dataEntry2.append(histo)
        }
        
        var dataEntry3 = [ChartDataEntry]()
        for i in 0..<closeValues.count - 1{
            let histo = ChartDataEntry(x: Double(i), y: bullArray["downmove"]![i])
            dataEntry3.append(histo)
        }
        
        let dataSet1 = LineChartDataSet(entries: dataEntry1, label: "")
        dataSet1.drawValuesEnabled = false
        dataSet1.drawCirclesEnabled = false
        dataSet1.mode = .linear
        dataSet1.lineWidth = 2
        dataSet1.colors = [.purple]
        
        let dataSet2 = LineChartDataSet(entries: dataEntry2, label: "")
        dataSet2.drawValuesEnabled = false
        dataSet2.drawCirclesEnabled = false
        dataSet2.mode = .linear
        dataSet2.lineWidth = 2
        dataSet2.colors = [.orange]
        
        let dataSet3 = LineChartDataSet(entries: dataEntry3, label: "")
        dataSet3.drawValuesEnabled = false
        dataSet3.drawCirclesEnabled = false
        dataSet3.mode = .linear
        dataSet3.lineWidth = 2
        dataSet3.colors = [.blue]
        
        let data = CombinedChartData()
        data.lineData = LineChartData(dataSets: [dataSet1,dataSet2,dataSet3])
        combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    
    func setupAroonIndicator() {
        let yValues = AroonIndicatorDown(high: highValues, low: lowValues)
        var chartEntry = [BarChartDataEntry]()
        var colours = [UIColor]()
        for i in 0..<yValues.count {
            let histo = BarChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
            if yValues[i] <= 10.0 {
                colours.append(.red)
            } else {
                colours.append(.green)
            }
        }
        let chartDataSet = BarChartDataSet(entries: chartEntry, label: "")
        chartDataSet.drawValuesEnabled = false
        //        chartDataSet.drawCirclesEnabled = false
        //        chartDataSet.mode = .linear
        //        chartDataSet.lineWidth = 2
        chartDataSet.colors = colours
        
        let data = CombinedChartData()
        let barData = BarChartData(dataSets: [chartDataSet])
        data.barData = barData
        self.combinedCV.data = data
        combinedCV.legend.enabled = false
        //        combinedCV.delegate = self
        combinedCV.doubleTapToZoomEnabled = false
        combinedCV.scaleYEnabled = false
        combinedCV.pinchZoomEnabled = false
        combinedCV.setDragOffsetX(20)
        combinedCV.dragEnabled = true
        combinedCV.xAxis.labelPosition = .bottom
        combinedCV.autoScaleMinMaxEnabled = true
        combinedCV.clipDataToContentEnabled = true
        //        combinedCV.setVisibleXRange(minXRange: 1, maxXRange: 50)
        intervalTimeStampCases(xAxis: combinedCV.xAxis)
    }
    
    func setupATR() {
        let yValues = ATR(period: 20)
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupChandlerExit() {
        let yValues = self.chandlerExit()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupCCI() {
        let yValues = self.CCI()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupDetrendedPriceOscillator() {
        let yValues = detrendedPriceOscillator()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupAvgHighLow() {
        let yValues = self.avgHighLow(period: 20)
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    func setupIchimokuCloud() {
        var lastClose = [Double]()
        var conversionLine = [Double]()
        var baseLine = [Double]()
        var spanA = [Double]()
        var spanB = [Double]()
        let avg26 = self.avgHighLow(period: 26)
        let avg9 = self.avgHighLow(period: 9)
        let avg52 = self.avgHighLow(period: 52)
        
        baseLine = avg26
        conversionLine = avg9[avg9.count - baseLine.count...avg9.count - 1].compactMap({$0})
        spanB = avg52
        for i in 26..<closeValues.count {
            lastClose.append(closeValues[i])
            spanA.append((conversionLine[i - 26] + baseLine[i - 26]) / 2)
        }
        
        var chartEntry1 = [ChartDataEntry]()
        for i in 0..<lastClose.count {
            let histo = ChartDataEntry(x: Double(i), y: lastClose[i])
            chartEntry1.append(histo)
        }
        let chartDataSet1 = LineChartDataSet(entries: chartEntry1, label: "")
        chartDataSet1.drawValuesEnabled = false
        chartDataSet1.drawCirclesEnabled = false
        chartDataSet1.mode = .linear
        chartDataSet1.lineWidth = 2
        chartDataSet1.colors = [.red]
        
        var chartEntry2 = [ChartDataEntry]()
        for i in 0..<conversionLine.count {
            let histo = ChartDataEntry(x: Double(i), y: conversionLine[i])
            chartEntry2.append(histo)
        }
        let chartDataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        chartDataSet2.drawValuesEnabled = false
        chartDataSet2.drawCirclesEnabled = false
        chartDataSet2.mode = .linear
        chartDataSet2.lineWidth = 2
        chartDataSet2.colors = [.blue]
        
        var chartEntry3 = [ChartDataEntry]()
        for i in 0..<baseLine.count {
            let histo = ChartDataEntry(x: Double(i), y: baseLine[i])
            chartEntry3.append(histo)
        }
        let chartDataSet3 = LineChartDataSet(entries: chartEntry3, label: "")
        chartDataSet3.drawValuesEnabled = false
        chartDataSet3.drawCirclesEnabled = false
        chartDataSet3.mode = .linear
        chartDataSet3.lineWidth = 2
        chartDataSet3.colors = [.green]
        
        var chartEntry4 = [ChartDataEntry]()
        for i in 0..<spanA.count {
            let histo = ChartDataEntry(x: Double(i), y: spanA[i])
            chartEntry4.append(histo)
        }
        let chartDataSet4 = LineChartDataSet(entries: chartEntry4, label: "")
        chartDataSet4.drawValuesEnabled = false
        chartDataSet4.drawCirclesEnabled = false
        chartDataSet4.mode = .linear
        chartDataSet4.lineWidth = 2
        chartDataSet4.colors = [.purple]
        
        var chartEntry5 = [ChartDataEntry]()
        for i in 0..<spanB.count {
            let histo = ChartDataEntry(x: Double(i), y: spanB[i])
            chartEntry5.append(histo)
        }
        let chartDataSet5 = LineChartDataSet(entries: chartEntry5, label: "")
        chartDataSet5.drawValuesEnabled = false
        chartDataSet5.drawCirclesEnabled = false
        chartDataSet5.mode = .linear
        chartDataSet5.lineWidth = 2
        chartDataSet5.colors = [.orange]
        
        let data = CombinedChartData()
        let lineData = LineChartData(dataSets: [chartDataSet1,chartDataSet2,chartDataSet3,chartDataSet4,chartDataSet5])
        data.lineData = lineData
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
        
    }
    
    func setupKaufmans () {
        let yValues = KaufmansMA()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupKDJOscillator() {
        let yValues1 = BullKDJOscillatorValueK()
        var chartEntry1 = [ChartDataEntry]()
        for i in 0..<yValues1.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues1[i])
            chartEntry1.append(histo)
        }
        
        let chartDataSet1 = LineChartDataSet(entries: chartEntry1, label: "")
        chartDataSet1.drawValuesEnabled = false
        chartDataSet1.drawCirclesEnabled = false
        chartDataSet1.mode = .linear
        chartDataSet1.lineWidth = 2
        chartDataSet1.colors = [.brown]
        
        let yValues2 = BullKDJOscillatorValueD()
        var chartEntry2 = [ChartDataEntry]()
        for i in 0..<yValues2.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues2[i])
            chartEntry2.append(histo)
        }
        
        let chartDataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        chartDataSet2.drawValuesEnabled = false
        chartDataSet2.drawCirclesEnabled = false
        chartDataSet2.mode = .linear
        chartDataSet2.lineWidth = 2
        chartDataSet2.colors = [.red]
        
        let yValues3 = BullKDJOscillatorValueJ()
        var chartEntry3 = [ChartDataEntry]()
        for i in 0..<yValues3.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues3[i])
            chartEntry3.append(histo)
        }
        
        let chartDataSet3 = LineChartDataSet(entries: chartEntry3, label: "")
        chartDataSet3.drawValuesEnabled = false
        chartDataSet3.drawCirclesEnabled = false
        chartDataSet3.mode = .linear
        chartDataSet3.lineWidth = 2
        chartDataSet3.colors = [.green]
        
        let data = CombinedChartData()
        let lineData = LineChartData(dataSets: [chartDataSet1,chartDataSet2,chartDataSet3])
        data.lineData = lineData
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    
    func setupMoneyFlowIndex() {
        let yValues = self.MoneyFlowIndex()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    
    func setupOBV() {
        let yValues = self.OBV()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    
    func setupPivotHighLow() {
        let yValues = self.PivotHighLowL()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        let yValues2 = self.PivotHighLowH()
        var chartEntry2 = [ChartDataEntry]()
        for i in 0..<yValues2.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues2[i])
            chartEntry2.append(histo)
        }
        
        let dataSet1 = LineChartDataSet(entries: chartEntry, label: "")
        dataSet1.drawValuesEnabled = false
        dataSet1.drawCirclesEnabled = false
        dataSet1.mode = .linear
        dataSet1.lineWidth = 2
        dataSet1.colors = [.brown]
        
        let dataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        dataSet2.drawValuesEnabled = false
        dataSet2.drawCirclesEnabled = false
        dataSet2.mode = .linear
        dataSet2.lineWidth = 2
        dataSet2.colors = [.red]
        
        let data = CombinedChartData()
        data.lineData = LineChartData(dataSets: [dataSet1,dataSet2])
        
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    
    func setupPriceChannel() {
        let yValues1 = self.PriceChannelL()
        var chartEntry1 = [ChartDataEntry]()
        for i in 0..<yValues1.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues1[i])
            chartEntry1.append(histo)
        }
        
        let chartDataSet1 = LineChartDataSet(entries: chartEntry1, label: "")
        chartDataSet1.drawValuesEnabled = false
        chartDataSet1.drawCirclesEnabled = false
        chartDataSet1.mode = .linear
        chartDataSet1.lineWidth = 2
        chartDataSet1.colors = [.brown]
        
        let yValues2 = self.PriceChannelM()
        var chartEntry2 = [ChartDataEntry]()
        for i in 0..<yValues2.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues2[i])
            chartEntry2.append(histo)
        }
        
        let chartDataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        chartDataSet2.drawValuesEnabled = false
        chartDataSet2.drawCirclesEnabled = false
        chartDataSet2.mode = .linear
        chartDataSet2.lineWidth = 2
        chartDataSet2.colors = [.red]
        
        let yValues3 = self.PriceChannelU()
        var chartEntry3 = [ChartDataEntry]()
        for i in 0..<yValues3.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues3[i])
            chartEntry3.append(histo)
        }
        
        let chartDataSet3 = LineChartDataSet(entries: chartEntry3, label: "")
        chartDataSet3.drawValuesEnabled = false
        chartDataSet3.drawCirclesEnabled = false
        chartDataSet3.mode = .linear
        chartDataSet3.lineWidth = 2
        chartDataSet3.colors = [.green]
        
        let data = CombinedChartData()
        let lineData = LineChartData(dataSets: [chartDataSet1,chartDataSet2,chartDataSet3])
        data.lineData = lineData
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    
    func setupPSAR() {
        let yValues = self.PSAR()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    
    func setupRSI() {
        let yValues = RSI(data: closeValues)
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    
    func setupVolumeWeightedAveragePrice () {
        let yValues = VolumeWeightedAveragePrice()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    func setupTRIXIndicator() {
        let yValues = TRIXIndicator()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        
        setLineChart(entry: chartEntry)
    }
    func setupTrendContinuationFactorPOS() {
        let yValues = TrendContinuationFactorPOS()
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
        
    }
    
    func setupSuperTrendDown() {
        let yValues = SuperTrendDown(r: 5, period: 20, multiplier: 2)
        var chartEntry = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues[i])
            chartEntry.append(histo)
        }
        setLineChart(entry: chartEntry)
    }
    
    func setupBullishStochValues() {
        let yValues1 = BullishStochDvalue()
        var chartEntry1 = [ChartDataEntry]()
        for i in 0..<yValues1.DValue.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues1.DValue[i])
            chartEntry1.append(histo)
        }
        
        let yValues2 = yValues1.KValue
        var chartEntry2 = [ChartDataEntry]()
        for i in 0..<yValues2.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues2[i])
            chartEntry2.append(histo)
        }
        
        let chartDataSet1 = LineChartDataSet(entries: chartEntry1, label: "")
        chartDataSet1.drawValuesEnabled = false
        chartDataSet1.drawCirclesEnabled = false
        chartDataSet1.mode = .linear
        chartDataSet1.lineWidth = 2
        chartDataSet1.colors = [.green]
        
        let chartDataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        chartDataSet2.drawValuesEnabled = false
        chartDataSet2.drawCirclesEnabled = false
        chartDataSet2.mode = .linear
        chartDataSet2.lineWidth = 2
        chartDataSet2.colors = [.red]
        
        
        let data = CombinedChartData()
        let lineData = LineChartData(dataSets: [chartDataSet1,chartDataSet2])
        data.lineData = lineData
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    
    func setupKeltnerChannel () {
        let yValues = KELTNERCHANNEL()
        var chartEntry1 = [ChartDataEntry]()
        for i in 0..<yValues.middle.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues.middle[i])
            chartEntry1.append(histo)
        }
        
        var chartEntry2 = [ChartDataEntry]()
        for i in  0..<yValues.lower.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues.lower[i])
            chartEntry2.append(histo)
        }
        
        var chartEntry3 = [ChartDataEntry]()
        for i in 0..<yValues.upper.count {
            let histo = ChartDataEntry(x: Double(i), y: yValues.upper[i])
            chartEntry3.append(histo)
        }
        
        let dataSet1 = LineChartDataSet(entries: chartEntry1, label: "")
        dataSet1.drawValuesEnabled = false
        dataSet1.drawCirclesEnabled = false
        dataSet1.mode = .linear
        dataSet1.lineWidth = 2
        dataSet1.colors = [.red]
        
        let dataSet2 = LineChartDataSet(entries: chartEntry2, label: "")
        dataSet2.drawValuesEnabled = false
        dataSet2.drawCirclesEnabled = false
        dataSet2.mode = .linear
        dataSet2.lineWidth = 2
        dataSet2.colors = [.blue]
        
        let dataSet3 = LineChartDataSet(entries: chartEntry3, label: "")
        dataSet3.drawValuesEnabled = false
        dataSet3.drawCirclesEnabled = false
        dataSet3.mode = .linear
        dataSet3.lineWidth = 2
        dataSet3.colors = [.green]
        
        let data = CombinedChartData()
        data.lineData = LineChartData(dataSets: [dataSet1,dataSet2,dataSet3])
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
        
    }
    
    func setupBollingerBands () {
//        let a = calculateEMA(20)
//        let b = (2*getStandardDeviation(values: closeValues, mean: 20))
//
//        var BOLU = [Double]()
//        for i in 0..<a.count {
//            BOLU.append(a[i]+b)
//        }
//
//        var BOLD = [Double]()
//        for i in 0..<a.count {
//            BOLD.append(a[i]-b)
//        }
//
//        let BOLM = calculateEMA(20)
//
//        var BOLUDataEntries = [ChartDataEntry]()
//        for i in 0..<BOLU.count {
//            let histo = ChartDataEntry(x: Double(i), y: BOLU[i])
//            BOLUDataEntries.append(histo)
//        }
//
//        var BOLDDataEntries = [ChartDataEntry]()
//        for i in 0..<BOLD.count {
//            let histo = ChartDataEntry(x: Double(i), y: BOLD[i])
//            BOLDDataEntries.append(histo)
//        }
//
//        var BOLMDataEntries = [ChartDataEntry]()
//        for i in 0..<BOLM.count {
//            let histo = ChartDataEntry(x: Double(i), y: BOLM[i])
//            BOLMDataEntries.append(histo)
//        }
//
//
//        let BOLUDataSets = LineChartDataSet(entries: BOLUDataEntries, label: "")
//        BOLUDataSets.drawCirclesEnabled = false
//        BOLUDataSets.colors = [.purple]
//        BOLUDataSets.mode = .linear
//        BOLUDataSets.drawValuesEnabled = false
//        BOLUDataSets.lineWidth = 3
//
//        let BOLDDataSets = LineChartDataSet(entries: BOLDDataEntries, label: "")
//        BOLDDataSets.drawCirclesEnabled = false
//        BOLDDataSets.colors = [.orange]
//        BOLDDataSets.mode = .linear
//        BOLDDataSets.drawValuesEnabled = false
//        BOLDDataSets.lineWidth = 3
//
//        let BOLMDataSets = LineChartDataSet(entries: BOLMDataEntries, label: "")
//        BOLMDataSets.drawCirclesEnabled = false
//        BOLMDataSets.colors = [.blue]
//        BOLMDataSets.mode = .linear
//        BOLMDataSets.drawValuesEnabled = false
//        BOLMDataSets.lineWidth = 3
//
//        let lineData = LineChartData(dataSets: [BOLUDataSets,BOLDDataSets,BOLMDataSets])
//        let combineChartData = CombinedChartData()
//        combineChartData.lineData = lineData
//        combinedCV.data = combineChartData
//        commonPropertiesOfCombinedChart()
    }
    
    //MARK: - Calculations and Other functions
    func getStandardDeviation(values : [Double], mean : Double) -> Double {
        let mapValue = values.map{
            return pow(Double($0) - mean,2)
        }.reduce(0.0) { a, b in
            a + b
        }
        let value  = sqrt(mapValue/Double(values.count))
        return value
    }
    
    func KELTNERCHANNEL() -> (middle: [Double], lower : [Double], upper : [Double]){
        let ATR = self.ATR(period: 10)
        let EMA = self.indicatorEMA(yValues: closeValues, period: 20)
        let newATR = ATR.enumerated().map({$1*2})
        let atr2 = newATR
        let upperKC = EMA.enumerated().map({$1 + atr2[$0]})
        let lowerKC = EMA.enumerated().map({$1 - atr2[$0]})
        let middleKC = upperKC.enumerated().map({($1 + lowerKC[$0])/2})
        return (middleKC,lowerKC,upperKC)
    }
    
    
    
    func BullishStochDvalue() -> (DValue : [Double], KValue : [Double]){
        var K_value = [Double]()
        var D_value = [Double]()
        var LL = [Double]()
        var HH = [Double]()
        for i in 0..<closeValues.count - 14 {
            let a = lowValues[i...i + 14]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = highValues[i...i + 14]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            LL.append(b.first(where: {$0 > $0 - 1}) ?? 0.0)
            HH.append(d.first(where: {$0 - 1 > $0}) ?? 0.0)
            K_value.append(((closeValues[i + 13] - LL[LL.count - 1]) / (HH[HH.count - 1] - LL[LL.count - 1])) * 100)
        }
        D_value = self.SMA(values: K_value, forInterval: 3)
        return (D_value,K_value)
    }
    
    func SuperTrendDown(r : Int, period : Int, multiplier : Int) -> [Double]{
        var upTrendBasic = [Double]()
        var downTrendBasic  = [Double]()
        var trueRange  = [Double]()
        var ATR  = [Double]()
        var ST  = [Double]()
        var upTrend  = [Double]()
        var downTrend  = [Double]()
        var Trend  = [Double]()
        let y = 7
        upTrend.append(0.0)
        downTrend.append(0.0)
        // ST.push(0.0);
        Trend.append(0.0)
        for i in 1..<closeValues.count {
            trueRange.append(max(max(abs(highValues[i] - lowValues[i]), abs(highValues[i] - closeValues[i - 1])), abs(closeValues[i - 1] - lowValues[i])))
        }
        for i in 0..<trueRange.count {
            if (ATR.count == 0) {
                ATR.append(trueRange[i])
            }
            ATR.append(((Double((y - 1)) * ATR[ATR.count - 1]) + trueRange[i]) / Double(y))
        }
        
        for i in 0..<ATR.count {
            upTrendBasic.append((highValues[i] + lowValues[i]) / 2 - (3 * ATR[i]))
            downTrendBasic.append((highValues[i] + lowValues[i]) / 2 + (3 * ATR[i]))
            if (i >= 1) {
                upTrend.append((closeValues[i - 1] > upTrend[upTrend.count - 1] ? max(upTrend[upTrend.count - 1], upTrendBasic[upTrendBasic.count - 1]) : upTrendBasic[upTrendBasic.count - 1]))
                downTrend.append((closeValues[i - 1] < downTrend[downTrend.count - 1]) ? min(downTrend[downTrend.count - 1], downTrendBasic[downTrendBasic.count - 1]) : downTrendBasic[downTrendBasic.count - 1])
                Trend.append(closeValues[i] > downTrend[downTrend.count - 2] ? 1.0 : closeValues[i] < upTrend[upTrend.count - 2] ? -1.0 : Trend[Trend.count - 1])
                ST.append((Trend[Trend.count - 1] == 1.0) ? upTrend[upTrend.count - 1] : downTrend[downTrend.count - 1])
            }
        }
        return ST
    }
    
    func setLineChart(entry : [ChartDataEntry]) {
        let dataSet = LineChartDataSet(entries: entry, label: "")
        dataSet.drawValuesEnabled = false
        dataSet.drawCirclesEnabled = false
        dataSet.mode = .linear
        dataSet.lineWidth = 2
        dataSet.colors = [UIColor.random()]
        
        let data = CombinedChartData()
        let lineData = LineChartData(dataSets: [dataSet])
        data.lineData = lineData
        self.combinedCV.data = data
        commonPropertiesOfCombinedChart()
    }
    func TrendContinuationFactorPOS() -> [Double]{
        var posChange = [Double]()
        var negChange = [Double]()
        var posCF = [Double]()
        var negCF = [Double]()
        var posTCF = [Double]()
        var negTCF = [Double]()
        
        for i in 1..<closeValues.count {
            var difference = Double()
            difference = closeValues[i] - closeValues[i - 1]
            posChange.append(difference > 0.0 ? difference : 0.0)
            negChange.append(difference < 0.0 ? abs(difference) : 0.0)
            if (posCF.count == 0) {
                posCF.append(posChange[posChange.count - 1])
                negCF.append(negChange[negChange.count - 1])
            }
            else {
                posCF.append((posChange[posChange.count - 1] == 0.0) ? 0.0 : (posChange[posChange.count - 1] + posCF[posCF.count - 1]))
                negCF.append((negChange[negChange.count - 1] == 0.0) ? 0.0 : (negChange[(negChange.count - 1)] + negCF[negCF.count - 1]))
            }
            if (posChange.count > 35) {
                posTCF.append((posChange[posChange.count - 35...posChange.count - 1].reduce(.zero, +)) - (negCF[negCF.count - 35...negCF.count - 1].reduce(.zero, +)))
                negTCF.append((negChange[negChange.count - 35...negChange.count - 1].reduce(.zero, +)) - (posCF[posCF.count - 35...posCF.count - 1].reduce(.zero, +)))
                
            }
        }
        return posTCF
    }
    func TRIXIndicator() -> [Double]{
        var EMAOne = [Double]()
        var EMATwo = [Double]()
        var EMAThree = [Double]()
        var TRIXValue = [Double]()
        EMAOne = self.indicatorEMA(yValues: closeValues, period: 15)
        EMATwo = self.indicatorEMA(yValues: EMAOne, period: 15)
        EMAThree = self.indicatorEMA(yValues: EMATwo, period: 15)
        
        for i in 1..<EMAThree.count {
            TRIXValue.append(((EMAThree[i]) - EMAThree[i - 1]) / EMAThree[i - 1])
        }
        return TRIXValue.map({$0.truncate(places: 2)})
    }
    
    func  VolumeWeightedAveragePrice() -> [Double]{
        var typicalPrice = [Double]()
        var pvVal = [Double]()
        var VWMAValue = [Double]()
        for i in 0..<volumeValues.count {
            typicalPrice.append((highValues[i] + lowValues[i] + closeValues[i]) / 3)
        }
        for i in 0..<typicalPrice.count {
            pvVal.append(typicalPrice[i] * volumeValues[i])
        }
        for i in 0..<pvVal.count - 5 {
            if (VWMAValue.count == 0) {
                VWMAValue.append(pvVal[i...i + 3].reduce(.zero, +) / volumeValues[i...i + 3].reduce(.zero, +))
            }
            VWMAValue.append(pvVal[i...i + 4].reduce(.zero, +) / volumeValues[i...i + 4].reduce(.zero, +))
        }
        return VWMAValue
    }
    
    func  RSI(data : [Double]) -> [Double]{
        var difference = [Double]()
        var gain = [Double]()
        var loss = [Double]()
        var avgGain = [Double]()
        var avgLoss = [Double]()
        var RSI = [Double]()
        for i in 0..<data.count {
            if i > 0 {
                difference.append(data[i] - data[i - 1])
                gain.append((difference[difference.count - 1] >= 0) ? difference[difference.count - 1] : 0.0)
                loss.append((difference[difference.count - 1] < 0) ? abs(difference[difference.count - 1]) : 0.0)
            }
        }
        
        for i in 14..<gain.count {
            if (avgGain.count == 0) {
                avgLoss.append(loss[loss.count - loss.count...i - 1].reduce(.zero, +))
                avgGain.append(gain[gain.count - gain.count...i - 1].reduce(.zero, +))
            }
            avgGain.append((avgGain[avgGain.count - 1] * 13 + gain[i]) / 14)
            avgLoss.append((avgLoss[avgLoss.count - 1] * 13 + loss[i]) / 14)
            RSI.append(100 - (100 / (1 + avgGain[avgGain.count - 1] / avgLoss[avgLoss.count - 1])))
        }
        return RSI
    }
    
    
    func  PSAR() -> [Double] {
        let Start = 0.02, Increment = 0.02, MaxValue = 0.2;
        var PSAR = [Double]()
        var pos = [Bool]()
        var maxMin = [Double]()
        var AccFactor = [Double]()
        var prev = [Double]()
        var trendValue = [Bool]()
        for i in 1..<closeValues.count {
            if (PSAR.count == 0) {
                PSAR.append(0.0)
                pos.append(false)
                maxMin.append(0.0)
                AccFactor.append(0.0)
                prev.append(0.0)
                trendValue.append(false)
            }
            prev.append(PSAR[PSAR.count - 1])
            trendValue.append(false)
            if (i == 1) {
                if (closeValues[i] > closeValues[i - 1]) {
                    pos.append(true)
                    maxMin.append(max(highValues[i], highValues[i - 1]))
                    prev.append(min(lowValues[i], lowValues[i - 1]))
                }
                else {
                    pos.append(false)
                    maxMin.append(min(lowValues[i], lowValues[i - 1]))
                    prev.append(max(highValues[i], highValues[i - 1]))
                }
                AccFactor.append(Start)
            }
            else {
                pos.append(pos[pos.count - 1])
                AccFactor.append(AccFactor[AccFactor.count - 1])
                maxMin.append(maxMin[maxMin.count - 1])
                
            }
            if (pos[pos.count - 1] == true) {
                if (highValues[i] > maxMin[maxMin.count - 1]) {
                    maxMin.append(highValues[i])
                    AccFactor.append(min(AccFactor[AccFactor.count - 1] + Increment, MaxValue))
                }
                if (lowValues[i] <= prev[prev.count - 1]) {
                    pos.append(false)
                    PSAR.append(maxMin[maxMin.count - 1])
                    maxMin.append(lowValues[i])
                    AccFactor.append(Start)
                    trendValue.append(true)
                }
            }
            else {
                if (lowValues[i] < maxMin[maxMin.count - 1]) {
                    maxMin.append(lowValues[i])
                    AccFactor.append(min(AccFactor[AccFactor.count - 1] + Increment, MaxValue))
                }
                if (highValues[i] >= prev[prev.count - 1]) {
                    pos.append(true)
                    PSAR.append(maxMin[maxMin.count - 1])
                    maxMin.append(highValues[i])
                    AccFactor.append(Start)
                    trendValue.append(true)
                }
            }
            if (!trendValue[trendValue.count - 1]) {
                PSAR.append(prev[prev.count - 1] + AccFactor[AccFactor.count - 1] * (maxMin[maxMin.count - 1] - prev[prev.count - 1]))
                if (pos[pos.count - 1] == true) {
                    if (PSAR[PSAR.count - 1] >= lowValues[i]) {
                        PSAR.append(lowValues[i] - 0.0)
                    }
                }
                if (pos[(pos.count - 1)] == false) {
                    if (PSAR[PSAR.count - 1] <= highValues[i]) {
                        PSAR.append(highValues[i] + 0.0)
                    }
                }
            }
        }
        return PSAR
    }
    
    func PriceChannelM() -> [Double]{
        var upperPC = [Double]()
        var lowerPC = [Double]()
        var middlePC = [Double]()
        for i in 20..<closeValues.count {
            let a = closeValues[i - 20...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = closeValues[i - 20...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            upperPC.append(b.first(where: {$0 - 1 > $0 }) ?? 0.0)
            lowerPC.append(d.first(where: {$0 > $0 - 1 }) ?? 0.0)
            middlePC.append((lowerPC[lowerPC.count - 1] + upperPC[upperPC.count - 1]) / 2)
        }
        return middlePC
    }
    
    func PriceChannelU() -> [Double]{
        var upperPC = [Double]()
        var lowerPC = [Double]()
        var middlePC = [Double]()
        for i in 20..<closeValues.count {
            let a = closeValues[i - 20...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = closeValues[i - 20...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            upperPC.append(b.first(where: {$0 - 1 > $0 }) ?? 0.0)
            lowerPC.append(d.first(where: {$0 > $0 - 1 }) ?? 0.0)
            middlePC.append((lowerPC[lowerPC.count - 1] + upperPC[upperPC.count - 1]) / 2)
        }
        return upperPC
    }
    
    func PriceChannelL() -> [Double]{
        var upperPC = [Double]()
        var lowerPC = [Double]()
        var middlePC = [Double]()
        for i in 20..<closeValues.count {
            let a = closeValues[i - 20...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = closeValues[i - 20...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            upperPC.append(b.first(where: {$0 - 1 > $0 }) ?? 0.0)
            lowerPC.append(d.first(where: {$0 > $0 - 1 }) ?? 0.0)
            middlePC.append((lowerPC[lowerPC.count - 1] + upperPC[upperPC.count - 1]) / 2)
        }
        return lowerPC
    }
    
    func PivotHighLowL() -> [Double]{
        var pivotLow = [Double]()
        var pivotHigh = [Double]()
        let bar = 10
        pivotHigh.append(0.0)
        pivotLow.append(0.0)
        for i in bar..<closeValues.count {
            let mipoint = ((i) + (i - bar)) / 2
            var high = false
            var low = false
            let a = highValues[i - bar...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            if (highValues[mipoint] == b.first(where: {$0 - 1 > $0})) {
                high = true
            }
            else {
                high = false
            }
            let c = lowValues[i - bar...i]
            previous = c.first ?? 0
            let d = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            
            if (lowValues[mipoint] == d.first(where: {$0 > $0 - 1})) {
                low = true
            }
            else {
                low = false
            }
            
            if (high == true) {
                pivotHigh.append(highValues[mipoint])
            }
            else if (low == true) {
                pivotLow.append(lowValues[mipoint])
            }
            else {
                pivotHigh.append(0.0)
                pivotLow.append(0.0)
            }
        }
        
        return pivotLow
        
    }
    func PivotHighLowH() -> [Double]{
        var pivotLow = [Double]()
        var pivotHigh = [Double]()
        let bar = 10
        pivotHigh.append(0.0)
        pivotLow.append(0.0)
        for i in bar..<closeValues.count {
            let mipoint = ((i) + (i - bar)) / 2
            var high = false
            var low = false
            let a = highValues[i - bar...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            if (highValues[mipoint] == b.first(where: {$0 - 1 > $0})) {
                high = true
            }
            else {
                high = false
            }
            let c = lowValues[i - bar...i]
            previous = c.first ?? 0
            let d = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            
            if (lowValues[mipoint] == d.first(where: {$0 > $0 - 1})) {
                low = true
            }
            else {
                low = false
            }
            
            if (high == true) {
                pivotHigh.append(highValues[mipoint])
            }
            else if (low == true) {
                pivotLow.append(lowValues[mipoint])
            }
            else {
                pivotHigh.append(0.0)
                pivotLow.append(0.0)
            }
        }
        
        return pivotHigh
        
    }
    
    func OBV() -> [Double]{
        var current_OBV = [Double]()
        
        for i in 1..<closeValues.count {
            
            if (current_OBV.count == 0) {
                
                current_OBV.append(0.0)
            }
            if (closeValues[i] > closeValues[i - 1]) {
                
                current_OBV.append(current_OBV[current_OBV.count - 1] + volumeValues[i])
                
            } else if (closeValues[i] < closeValues[i - 1]) {
                
                current_OBV.append(current_OBV[current_OBV.count - 1] - volumeValues[i])
            }
            else {
                
                current_OBV.append(current_OBV[current_OBV.count - 1])
                
            }
        }
        
        return current_OBV
        
    }
    
    func MoneyFlowIndex() -> [Double] {
        var typical_price = [Double]()
        var RMF = [Double]()
        var MFR = [Double]()
        var positive = [Double]()
        var negative = [Double]()
        var MFI = [Double]()
        for i in 0..<closeValues.count {
            typical_price.append(((closeValues[i] + highValues[i] + lowValues[i]) / 3))
            if (i != 0) {
                RMF.append(typical_price[typical_price.count - 2] < typical_price[typical_price.count - 1] ? typical_price[i] * volumeValues[i] : (typical_price[i] * (-volumeValues[i])))
            }
        }
        for i in 0..<RMF.count - 14 {
            positive.append(RMF[i...i + 14].filter({$0 > 0}).reduce(.zero, +))
            negative.append(abs(RMF[i...i + 14].filter({$0 < 0}).reduce(.zero, +)))
            MFR.append(positive[i] / negative[i])
            MFI.append(100 - (100 / (1 + MFR[MFR.count - 1])))
        }
        return MFI
    }
    
    func KDJSMA(_ closeList : [Double], _ period : Int , _ coeff : Double) -> [Double]{
        var kdjSMA = [Double]()
        kdjSMA.append(1.0)
        for i in 0..<closeList.count {
            
            kdjSMA.append((coeff * closeList[i] + (Double(period) - coeff) * kdjSMA[kdjSMA.count - 1]) / Double(period))
        }
        return kdjSMA
    }
    func BullKDJOscillatorValueK() -> [Double]{
        var K_value = [Double]()
        var D_value = [Double]()
        var J_value = [Double]()
        var LL = [Double]()
        var RSV = [Double]()
        var HH = [Double]()
        for i in 9..<closeValues.count {
            let a = lowValues[i - 9...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = highValues[i - 9...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            LL.append(b.first(where: {$0 < $0 - 1}) ?? 0.0)
            HH.append(d.first(where: {$0 > $0 - 1 }) ?? 0.0)
            RSV.append(((closeValues[i] - LL[LL.count - 1]) / (HH[HH.count - 1] - LL[LL.count - 1])) * 100)
        }
        K_value = self.KDJSMA(RSV, 3, 1)
        D_value = self.KDJSMA(K_value, 3, 1)
        for i in 1..<D_value.count {
            J_value.append(3 * K_value[i - 1] - 2 * D_value[i])
        }
        return K_value
    }
    
    func BullKDJOscillatorValueD() -> [Double]{
        var K_value = [Double]()
        var D_value = [Double]()
        var J_value = [Double]()
        var LL = [Double]()
        var RSV = [Double]()
        var HH = [Double]()
        for i in 9..<closeValues.count {
            let a = lowValues[i - 9...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = highValues[i-9...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            LL.append(b.first(where: {$0 - 1 > $0}) ?? 0.0)
            HH.append(d.first(where: {$0 - 1 < $0}) ?? 0.0)
            RSV.append(((closeValues[i] - LL[LL.count - 1]) / (HH[HH.count - 1] - LL[LL.count - 1])) * 100)
        }
        K_value = self.KDJSMA(RSV, 3, 1)
        D_value = self.KDJSMA(K_value, 3, 1)
        for i in 1..<D_value.count {
            J_value.append(3 * K_value[i - 1] - 2 * D_value[i])
        }
        return D_value
    }
    
    func BullKDJOscillatorValueJ() -> [Double]{
        var K_value = [Double]()
        var D_value = [Double]()
        var J_value = [Double]()
        var LL = [Double]()
        var RSV = [Double]()
        var HH = [Double]()
        for i in 9..<closeValues.count {
            let a = lowValues[i - 9...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = highValues[i-9...i]
            previous = c.first ?? 0
            let d = c.map { element -> Double in
                defer { previous = element }
                return element
            }
            LL.append(b.first(where: {$0 > $0 - 1}) ?? 0.0)
            HH.append(d.first(where: {$0 - 1 > $0}) ?? 0.0)
            RSV.append(((closeValues[i] - LL[LL.count - 1]) / (HH[HH.count - 1] - LL[LL.count - 1])) * 100)
        }
        K_value = self.KDJSMA(RSV, 3, 1)
        D_value = self.KDJSMA(K_value, 3, 1)
        for i in 1..<D_value.count {
            J_value.append(3 * K_value[i - 1] - 2 * D_value[i])
        }
        return J_value
    }
    
    
    func KaufmansMA() -> [Double]{
        var changeVal, EfficiencyRatio, SCVal : Double
        let fastSC = 0.666667, slowSc = 0.064516
        //            var KAMovingAverage = [Double]()
        var kaufman = [Double]()
        var efficiencyr = [Double]()
        var scvalarr = [Double]()
        var changevalarr = [Double]()
        for i in 21..<closeValues.count {
            if (kaufman.count == 0) {
                kaufman.append(self.avg(closeValues[i - 21...i].compactMap({$0}))) //add average function here
            } else {
                changeVal = abs(closeValues[i] - closeValues[i - 20])
                EfficiencyRatio = (changeVal / self.VolatilitySum(closeValues[i - 22...i].compactMap({$0}), 21))
                efficiencyr.append(EfficiencyRatio)
                changevalarr.append(changeVal)
                SCVal = pow((EfficiencyRatio * (fastSC - slowSc) + slowSc), 2)
                scvalarr.append(SCVal)
                kaufman.append(kaufman[kaufman.count - 1] + (SCVal * (closeValues[i] - kaufman[kaufman.count - 1])))
            }
        }
        return kaufman
    }
    func  VolatilitySum(_ values : [Double],_ period : Int) -> Double{
        var closeDiff = [Double]()
        for i in 1..<values.count {
            closeDiff.append(abs(values[i] - values[i - 1]))
        }
        return (closeDiff[closeDiff.count - period...closeDiff.count - 1].reduce(.zero,+))
    }
    
    func avgHighLow(period : Int) -> [Double] {
        
        var highLowAvg = [Double]()
        var highestHigh = Double()
        var lowestLow = Double()
        for i in 0..<highValues.count - period {
            let a = highValues[i...i + period]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = lowValues[i...i + period]
            previous = c.first ?? 0
            let d = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            highestHigh = b.first(where: {$0 < $0 - 1}) ?? 0.0
            lowestLow = d.first(where: {$0 > $0 - 1}) ?? 0.0
            highLowAvg.append((highestHigh + lowestLow) / 2)
        }
        return highLowAvg
    }
    func detrendedPriceOscillator() -> [Double] {
        var SimpleMA = [Double]()
        var DPOValue = [Double]()
        
        for i in 20..<closeValues.count {
            let a = closeValues[i - 20...i]
            //            var previous = a.first ?? 0
            //            let b = a.map { element -> Double in
            //                defer { previous = element }
            //                return (element + previous / 20)
            //            }
            let b = a.reduce(.zero, +)
            //            let c = b.first(where: {$0 > $0 - 1}) ?? 0.0
            //            SimpleMA.push(closeList.slice(i - 20, i).reduce((prev, current) => { return ((parseFloat(prev) + parseFloat(current))) }, 0) / 20);
            SimpleMA.append(b)
            if (SimpleMA.count >= 11) {
                DPOValue.append(closeValues[i] - SimpleMA[SimpleMA.count - 11])
            }
        }
        return DPOValue
    }
    
    func CCI () -> [Double]{
        var typicalPrice = [Double]()
        var CCI =  [Double]()
        var averageTP =  [Double]()
        var meanDeviation =  [Double]()
        for index in 0..<highValues.count {
            typicalPrice.append((highValues[index] + closeValues[index] + lowValues[index]) / 3)
        }
        for i in 20..<typicalPrice.count {
            var absAvg = [Double]()
            let newArray = typicalPrice[i - 20...i].map({$0})
            averageTP.append(self.avg(newArray))
            for j in 0..<newArray.count {
                absAvg.append(abs(newArray[j] - averageTP[averageTP.count - 1]))
                meanDeviation.append(self.avg(absAvg))
            }
            CCI.append((typicalPrice[i - 1] - averageTP[averageTP.count - 1]) / (0.015 * meanDeviation[meanDeviation.count - 1]))
        }
        return CCI
    }
    func chandlerExit() -> [Double]{
        var chandelierExit = [Double]()
        var maxHigh = Double()
        let avg = self.ATR(period: 22)
        for i in 0..<highValues.count - 22 {
            let a = highValues[i...i + 22]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            //            maxHigh = highList[i...i + 22].reduce((prev, current) => { return parseFloat((parseFloat(prev) > parseFloat(current)) ? prev : current) });
            maxHigh = b.first(where: {$0 > $0 - 1}) ?? 0.0
            chandelierExit.append(maxHigh - (avg[avg.count - 1] * 3))
        }
        return chandelierExit
    }
    func ATR(period: Int) -> [Double] {
        var trueRange = [Double]()
        var ATR = [Double]()
        for i in 1..<closeValues.count {
            trueRange.append(max(max(abs(highValues[i] - lowValues[i]), abs(highValues[i] - closeValues[i - 1])), abs(closeValues[i - 1] - lowValues[i])))
        }
        for i in 0..<trueRange.count {
            if (ATR.count == 0) {
                ATR.append(trueRange[i])
            }
            ATR.append(((Double((period - 1)) * ATR[ATR.count - 1]) + trueRange[i]) / Double(period))
        }
        return ATR
    }
    func avg(_ values: [Double]) -> Double{
        //        let a = values
        //        var previous = a.first ?? 0
        //        let b = a.map { element -> Double in
        //            defer { previous = element }
        //            return element > previous ? element : previous
        //        }
        //        //            maxHigh = highList[i...i + 22].reduce((prev, current) => { return parseFloat((parseFloat(prev) > parseFloat(current)) ? prev : current) });
        //                 let sum = b.first(where: {$0 > $0 - 1}) ?? 0.0
        //                 let avg = sum / values.count
        //                 return avg
        var sum = Double()
        for i in 0..<values.count {
            sum += values[i]
        }
        let avg = sum / Double(values.count)
        return avg
    }
    
    
    
    func commonPropertiesOfCombinedChart() {
        combinedCV.legend.enabled = false
        //        combinedCV.delegate = self
        combinedCV.doubleTapToZoomEnabled = false
        combinedCV.scaleYEnabled = false
        combinedCV.pinchZoomEnabled = false
        combinedCV.setDragOffsetX(20)
        combinedCV.dragEnabled = true
        combinedCV.xAxis.labelPosition = .bottom
        combinedCV.autoScaleMinMaxEnabled = true
        combinedCV.clipDataToContentEnabled = true
        combinedCV.setVisibleXRange(minXRange: 1, maxXRange: 50)
        intervalTimeStampCases(xAxis: combinedCV.xAxis)
    }
    func AroonIndicatorDown(high: [Double], low: [Double]) -> [Double]{
        var aroonObjUP = [Double]()
        var aroonObjDOWN = [Double]()
        var highIndex = [Int]()
        var lowIndex = [Int]()
        for i in 14..<high.count {
            //            let highb4 = (high[i - 14...i]).reduce((prev, current) = return Float((Float(prev) > Float(current)) ? prev : current) )
            let a = highValues[i - 14...i]
            var previous = a.first ?? 0
            let b = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            let c = a.map { element -> Double in
                defer { previous = element }
                return element
            }
            
            let highb4 = b.first(where: {$0 > $0 - 1}) ?? 0.0
            
            let highi = high.firstIndex(of: highb4 ) ?? 0
            highIndex.append(high[highi...i].count)
            //            let lowb4 = (high[i - 14...i]).reduce((prev, current) = return Float((Float(prev) < Float(current)) ? prev : current) )
            let lowb4 = c.first(where: {$0 < $0 - 1}) ?? 0.0
            let lowi = low.firstIndex(of: lowb4) ?? 0
            lowIndex.append(low[lowi...i].count)
            if (aroonObjDOWN.count >= 1) {
                var value1 = Double()
                var value2 = Double()
                let a = (((14 - Double(highIndex[highIndex.count - 1])) / 14) * 100)
                if a != aroonObjUP[aroonObjUP.count - 1] {
                    value1 = a
                } else {
                    value1 = 0.0
                }
                
                if a != aroonObjUP[aroonObjUP.count - 1] {
                    value2 = a
                } else {
                    value2 = 0.0
                }
                aroonObjUP.append(value1)
                aroonObjDOWN.append(value2)
                
            }
            else {
                aroonObjUP.append(((14 - Double(highIndex[highIndex.count - 1]) / 14) * 100));
                aroonObjDOWN.append(((14 - Double(lowIndex[lowIndex.count - 1])) / 14) * 100);
            }
        }

        return aroonObjDOWN
        
    }
    
    func SMA(values : [Double], forInterval : Int) -> [Double] {
        var array = [Double]()
        let sumOf20 = Double()
        var sum = Double()
        for i in 0..<forInterval {
            array.append(0.0)
            sum += values[i]
        }
        for i in forInterval..<values.count {
            sum = sumOf20 - (values[i] - Double(forInterval)) + values[i]
            array.append(sum/Double(forInterval))
        }
        return array
    }
    
    func bullDirectionalIndex() -> [String : [Double]]{
        var upMove = [Double]()
        var downMove = [Double]()
        var smoothPosDM = [Double]()
        var smoothNegDM = [Double]()
        var DX = [Double]()
        var ADI = [Double]()
        var posDM = 0.0, negDM = 0.0, trueRange = 0.0
        var avgTR = [Double]()
        for i in 0..<closeValues.count {
            if downMove.count == 0 {
                avgTR.append(0.0)
                smoothPosDM.append(0.0)
                smoothNegDM.append(0.0)
                upMove.append(0.0)
                downMove.append(0.0)
                
            }
            if i > 0 {
                trueRange = max(max(highValues[i] - lowValues[i], abs(highValues[i] - closeValues[i - 1])), abs(lowValues[i] - closeValues[i - 1]))
                posDM = highValues[i] - highValues[i - 1] > lowValues[i - 1] - lowValues[i] ? max(highValues[i] - highValues[i - 1], 0.0) : 0.0
                negDM = lowValues[i - 1] - lowValues[i] > highValues[i] - highValues[i - 1] ? max(lowValues[i - 1] - lowValues[i], 0.0) : 0.0
                
                
                avgTR.append(avgTR[avgTR.count - 1] - (avgTR[avgTR.count - 1] / 14) + trueRange)
                smoothPosDM.append(smoothPosDM[smoothPosDM.count - 1] - (smoothPosDM[smoothPosDM.count - 1] / 14) + posDM)
                smoothNegDM.append(smoothNegDM[smoothNegDM.count - 1] - (smoothNegDM[smoothNegDM.count - 1] / 14) + negDM)
                
                upMove.append(smoothPosDM[smoothPosDM.count - 1] / avgTR[avgTR.count - 1] * 100)
                downMove.append(smoothNegDM[smoothNegDM.count - 1] / avgTR[avgTR.count - 1] * 100)
                DX.append(abs(upMove[upMove.count - 1] - downMove[downMove.count - 1]) / (upMove[upMove.count - 1] + downMove[downMove.count - 1]) * 100)
            }
        }
        //        ADI = [...ADI, ...this.SMA(DX, 14)]
        ADI = SMA(values: DX, forInterval: 14)
        var bullArray = [String : [Double]]()
        bullArray["adi"] = ADI
        bullArray["upmove"] = upMove
        bullArray["downmove"] = downMove
        return bullArray
    }
    func calculateEMA(_ forInterval : Int) -> [Double] {
        let initialValue = closeValues.reduce(.zero , +)
        var EMAY = initialValue/Double(closeValues.count)
        //        var EMAY = 0.0
        var EMAT = 0.0
        let smoothing = Double(2)/Double(forInterval+1)
        var arrayEMA = [Double]()
        for i in 0..<closeValues.count {
            let a = Double(closeValues[i] * Double((Int(smoothing)/1+forInterval)))
            let b = Double(EMAY*Double((1-(Int(smoothing)/1+forInterval))))
            EMAT = a + b
            arrayEMA.append(EMAT)
            EMAY = EMAT
        }
        return arrayEMA
        
    }
    
    func heikenAshiValues() -> [[String:Double]] {
        var heikinAshi:[[String:Double]] = [[String:Double]]()
        for index in 0..<xValues.count {
            let open = openValues[index]
            let close = closeValues[index]
            let high = highValues[index]
            let low = lowValues[index]
            let haClose = (open + high + low + close)/4
            let haOpen = index == 0 ? open:((heikinAshi[index - 1]["open"] ?? 0.0) + (heikinAshi[index - 1]["close"] ?? 0.0))/2
            let haHigh:Double = [high,haOpen,haClose].max() ?? 0.0
            let haLow:Double = [low,haOpen,haClose].min() ?? 0.0
            heikinAshi.append(["high":haHigh,"low":haLow,"close":haClose,"open":haOpen])
        }
        return heikinAshi
    }
    
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
    
}
class MyCandleStickChartRenderer: CandleStickChartRenderer {
    
     var _xBounds = XBounds()
    
    var minValues = [Double]()
    var maxValues = [Double]()
//    var maxVisibleValues = [Double]()
    init (view: CandleStickChartView) {
        super.init(dataProvider: view, animator: view.chartAnimator, viewPortHandler: view.viewPortHandler)
    }
    
    override func drawValues(context: CGContext)
    {
       
        guard
            let dataProvider = dataProvider,
            let candleData = dataProvider.candleData
        else { return }
        
        // if values are drawn
        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for i in candleData.indices
            {
                guard let
                        dataSet = candleData[i] as? BarLineScatterCandleBubbleChartDataSetProtocol,
                      shouldDrawValues(forDataSet: dataSet)
                else { continue }
                
                let valueFont = dataSet.valueFont
                
                //                let formatter = dataSet.valueFormatter
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                //                let iconsOffset = dataSet.iconsOffset
                
                //                let angleRadians = (dataSet.valueLabelAngle * .pi / 180)
                
                _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
                
                let lineHeight = valueFont.lineHeight
                let yOffset: CGFloat = lineHeight + 5.0
//                for k in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1) {
//                    guard let e = dataSet.entryForIndex(k) as? CandleChartDataEntry else { break }
//                    minValues.append(e.low)
//                    maxValues.append(e.high)
//                }
                minValues.removeAll()
                maxValues.removeAll()
                for k in  0..<dataSet.entryCount {
                    guard let e = dataSet.entryForIndex(k) as? CandleChartDataEntry else { break }
                    minValues.append(e.low)
                    maxValues.append(e.high)
                }
                let range1 = _xBounds.min
                var range2 = _xBounds.min + 48
                print("Minimum: ",_xBounds.min)
                print("Maximum: ",_xBounds.max)
                print("Range: ",_xBounds.range)
                for j in stride(from: _xBounds.min, through: 50 + _xBounds.min, by: 1)
                {
                    if range1 >= 450{
                        range2 = (499 - range1) + range1
                    }
                    
                    let newMaxValues = maxValues[range1...range2]
                    let newMinValues = minValues[range1...range2]
          
                    guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else {
                        break }
                    
                    // need to show only min and max values
                    guard e.high == newMaxValues.max() || e.low == newMinValues.min() else {
                        continue }
 
                    
                    pt.x = CGFloat(e.x)
                    if e.high == newMaxValues.max() {
                        pt.y = CGFloat(e.high * phaseY)
                    } else if e.low == newMinValues.min() {
                        pt.y = CGFloat(e.low * phaseY)
                    }
                    pt = pt.applying(valueToPixelMatrix)
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        break
                    }
                    if (!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y))
                    {
                        continue
                    }
                    if dataSet.isDrawValuesEnabled
                    {
                        var textValue: String?
                        var align: NSTextAlignment = .center
                        
                        // customize position for min/max value
                        if e.high == newMaxValues.max() {
                            pt.y -= yOffset / 2
                            textValue = String(e.high) + "  →"
                            align = .right
                       
                        } else if e.low == newMinValues.min() {
                            pt.y -= yOffset / 5
                            textValue = "←  " + String(e.low)
                            align = .left
                         
                        }
                        if let textValue = textValue {
                            context.drawText(textValue, at: CGPoint(
                                x: pt.x,
                                y: pt.y ), align: align, attributes: [NSAttributedString.Key.font: valueFont, NSAttributedString.Key.foregroundColor: dataSet.valueTextColorAt(j)])
                        }
                    }
                }
            }
        }
    }
}

class TypesOfChartTVC : UITableViewCell {
    
    @IBOutlet weak var chartStyleLabel: UILabel!
}

enum Charts : String , CaseIterable{
    case HeikenAshi
    case BullAverageDirectionalIndex
    case Aroon
    case ATR
    case ChandlerExit
    case CCI
    case DetrendedPriceOscillator
    case AvgOfHighLow
    case IchimokuCloud
    case Kaufmans
    case KDJOscillator
    case MoneyFlowIndicator
    case OBV
    case PriceChannel
    case PSAR
    case RSI
    case VolumeWeightedAverage
    case TRIX
    case TrendContinuationFactor
    case SuperTrendDown
    case BullishStochValues
    case PivotHighLow
    case Keltner
    case MACD
    case BollinderBands
    
    var stringValue : String {
        switch self {
        case .HeikenAshi:
            return "Heiken Ashi"
        case .BullAverageDirectionalIndex:
            return "Bull Average Directional Index"
        case .Aroon:
            return "Aroon Indicator"
        case .ATR:
            return "ATR"
        case .ChandlerExit:
            return "Chandler Exit"
        case .CCI:
            return "CCI"
        case .DetrendedPriceOscillator:
            return "Detrended Price Oscillator"
        case .AvgOfHighLow:
            return "Average of High Low"
        case .IchimokuCloud:
            return "Ichimoku Cloud"
        case .Kaufmans:
            return "Kaufmans"
        case .KDJOscillator:
            return "KDJ Oscillator"
        case .MoneyFlowIndicator:
            return "Money Flow Indicator"
        case .OBV:
            return "OBV"
        case .PriceChannel:
            return "Price Channel"
        case .PSAR:
            return "Parabolic SAR Index"
        case .RSI:
            return "Relative Strength Index"
        case .VolumeWeightedAverage:
            return "Volume Weighted Average"
        case .TRIX:
            return "Triple Exponential Average"
        case .TrendContinuationFactor:
            return "Trend Continuation Factor"
        case .SuperTrendDown:
            return "Super Trend Down"
        case .BullishStochValues:
            return "Stochastic"
        case .PivotHighLow:
            return "Pivot High Low"
        case .Keltner:
            return "Keltner"
        case .MACD:
            return "MACD"
        case .BollinderBands:
            return "Bollinger Bands"
        }
    }
}
extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red:   .random(in: 0...1),
            green: .random(in: 0...1),
            blue:  .random(in: 0...1),
            alpha: 1.0
        )
    }
}

