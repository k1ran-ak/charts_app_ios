//
//  ViewController.swift
//  BidAsk
//
//  Created by Mac on 09/03/22.
//

import UIKit
import Starscream
import Alamofire
var selectedCoinPair = String()
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WebSocketDelegate, UISearchBarDelegate {

    //MARK: - Outlets
    
    @IBOutlet weak var topHolderView: UIView!
    
    @IBOutlet weak var selectedCryptoNameLabel: UILabel!
    
    @IBOutlet weak var dropDownImageView: UIImageView!
    
    @IBOutlet weak var cryptoTVHolderView: UIView!
    @IBOutlet weak var cryptoTV: UITableView!
    
    @IBOutlet weak var bottomHolderView: UIView!
    
    @IBOutlet weak var bidsTVHolderView: UIView!
    
    @IBOutlet weak var bidsTV: UITableView!
    
    @IBOutlet weak var asksTVHolderView: UIView!

    @IBOutlet weak var asksTV: UITableView!
    
    @IBOutlet weak var bottomBtnHolderView: UIView!
    
    @IBOutlet weak var coinSearchBar: UISearchBar!
    //MARK: - Local Variables
    let staticSymbols : [CryptoNames] = [CryptoNames.BNBBTC,CryptoNames.ETHUSDT,CryptoNames.BNBUSDT,CryptoNames.MATICUSDT,CryptoNames.SOLUSDT,CryptoNames.ADAUSDT,CryptoNames.LUNAUSDT]
    let initialSelection = [false,false,false,false,false,false,false]
    var model = Crypto()
    var isConnected = Bool()
    var socket : WebSocket!
    var  buyAskModel =  DepthDataModel()
    var isFirstTime = true
    var updateModel = DepthDataModel()
    var coinDataModel = CoinDataModel()
    var isFiltering = Bool()
    var allCoinsList = [Symbol]()
    var filteredCoins = [Symbol]()
    
    
    
    //MARK: - Class functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.model = Crypto(name: self.staticSymbols, self.initialSelection)
        self.getSymbols()
        print(model.name)
        self.initViews()
        self.cryptoTV.delegate = self
        self.cryptoTV.dataSource = self
        self.bidsTV.dataSource = self
        self.asksTV.dataSource = self
        self.coinSearchBar.delegate = self
      
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let socket = self.socket {
            if !isFirstTime {
                socket.forceDisconnect()
            }
        } else {
            return
        }
    }
   
    func initViews() {
        if #available(iOS 13.0, *) {
            self.dropDownImageView.image = UIImage(systemName: "triangle.circle.fill")
        } else {
            // Fallback on earlier versions
        }
//        self.dropDownImageView.transform = CGAffineTransform(rotationAngle: .pi)
        self.cryptoTV.register(UINib(nibName: "CryptoTVC", bundle: nil), forCellReuseIdentifier: "CryptoTVC")
        self.bidsTV.register(UINib(nibName: "BuyAskTVC", bundle: nil), forCellReuseIdentifier: "BuyAskTVC")
        self.asksTV.register(UINib(nibName: "BuyAskTVC", bundle: nil), forCellReuseIdentifier: "BuyAskTVC")
        self.cryptoTVHolderView.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapped(_:)))
        self.topHolderView.addGestureRecognizer(tap)
        self.bidsTVHolderView.border(colour: .black, width: 1)
        self.asksTVHolderView.border(colour: .black, width:  1)
        self.bidsTVHolderView.layer.cornerRadius = 5
        self.asksTVHolderView.layer.cornerRadius = 5
        self.topHolderView.layer.cornerRadius = 10
        self.topHolderView.border(colour: .black, width: 1)
        self.topHolderView.elevate(5)

    }

    
    //MARK: - Tap Action
    @objc func didTapped(_ sender: UITapGestureRecognizer?) {
        self.cryptoTVHolderView.isHidden = !self.cryptoTVHolderView.isHidden
//        self.dropDownImageView.transform = self.cryptoTVHolderView.isHidden ? CGAffineTransform(rotationAngle: .pi) : CGAffineTransform(rotationAngle: .pi*2)
    }
    
    //MARK: - Button Actions
    
    @IBAction func seeTimelineBtnAction(_ sender: Any) {
        if !selectedCoinPair.isEmpty{
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TimeLineViewController") as! TimeLineViewController
        vc.selectedCoinPair = selectedCoinPair
        self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    

    
    //MARK: - Search Bar delegates functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search for: ",searchText)
        self.updateCryptoTV(searchText)
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    func updateCryptoTV(_ searchText : String) {
        if searchText.isEmpty {
                filteredCoins.removeAll()
                isFiltering = false
            } else {
                filteredCoins = allCoinsList.filter{$0.symbol.range(of: searchText, options: .caseInsensitive) != nil }
                isFiltering = true
                self.cryptoTVHolderView.isHidden = false
            }
        cryptoTV.reloadData()
    }
    //MARK: - Crypto TV Delegates and Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case cryptoTV:
            return isFiltering ?  filteredCoins.count : allCoinsList.count
        case bidsTV:
            return self.buyAskModel.bids.count
        case asksTV:
            return self.buyAskModel.asks.count
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case cryptoTV:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoTVC", for: indexPath) as! CryptoTVC
            let data = isFiltering ? filteredCoins[indexPath.row] : allCoinsList[indexPath.row]
            cell.cryptoNameLabel.text = data.symbol
            if #available(iOS 13.0, *) {
                cell.selectedImageView.image = (data.isSelected ?? false) ? UIImage(systemName: "checkmark.diamond.fill") : UIImage(systemName: "")
            } else {
                // Fallback on earlier versions
            }
    //
            return cell
        case bidsTV:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuyAskTVC", for: indexPath) as! BuyAskTVC
            if !isFirstTime {
                for i in 0..<updateModel.bids.count {
                    if i == buyAskModel.bids.count {
                        self.buyAskModel.bids.append(contentsOf: updateModel.bids)
                        break
                    }
                    self.buyAskModel.bids[i] = updateModel.bids[i]
                }
                let price = self.buyAskModel.bids[indexPath.row].first?.toDouble()
                let quantity = self.buyAskModel.bids[indexPath.row].last?.toDouble()
                cell.priceLabel.text = price!.removeZerosFromEnd()
                cell.priceLabel.textColor = .red
                cell.quantityLabel.text = quantity!.removeZerosFromEnd()
                return cell
            }
            let price = self.buyAskModel.bids[indexPath.row].first?.toDouble()
            let quantity = self.buyAskModel.bids[indexPath.row].last?.toDouble()
            cell.priceLabel.text = price!.removeZerosFromEnd()
            cell.priceLabel.textColor = .red
            cell.quantityLabel.text = quantity!.removeZerosFromEnd()
            return cell
        case asksTV:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuyAskTVC", for: indexPath) as! BuyAskTVC
            if !isFirstTime {
                for i in 0..<updateModel.asks.count {
                    if i == buyAskModel.asks.count {
                        self.buyAskModel.asks.append(updateModel.asks[i])
                        break
                    }
                    self.buyAskModel.asks[i] = updateModel.asks[i]
                }
                let price = self.buyAskModel.asks[indexPath.row].first?.toDouble()
                let quantity = self.buyAskModel.asks[indexPath.row].last?.toDouble()
                cell.priceLabel.text = price!.removeZerosFromEnd()
                cell.priceLabel.textColor = .green
                cell.quantityLabel.text = quantity!.removeZerosFromEnd()
                return cell
            }
            let price = self.buyAskModel.asks[indexPath.row].first?.toDouble()
            let quantity = self.buyAskModel.asks[indexPath.row].last?.toDouble()
            cell.priceLabel.text = price!.removeZerosFromEnd()
            cell.priceLabel.textColor = .green
            cell.quantityLabel.text = quantity!.removeZerosFromEnd()
            return cell
        default:
            return UITableViewCell()
        }

    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if isFiltering {
            if (filteredCoins[indexPath.row].isSelected ?? false) == false && filteredCoins.contains(where: {$0.isSelected == true}) {
                repeat {
                let index = filteredCoins.firstIndex(where: {$0.isSelected == true}) ?? 0
                self.filteredCoins[index].isSelected = false
                } while (filteredCoins.contains(where: {$0.isSelected == true}))
            } else {
                print("Cant allow")
            }
            self.filteredCoins[indexPath.row].isSelected = true
        } else {
            if allCoinsList[indexPath.row].isSelected == false && allCoinsList.contains(where: {$0.isSelected == true}) {
                let index = allCoinsList.firstIndex(where: {$0.isSelected == true}) ?? 0
                self.allCoinsList[index].isSelected = false
            } else {
                print("Cant allow")
            }
            self.allCoinsList[indexPath.row].isSelected = true
        }
        //self.selectedCryptoNameLabel.text = isFiltering ? filteredCoins[indexPath.row].symbol : allCoinsList[indexPath.row].symbol
        self.isFirstTime = true
        self.coinSearchBar.text = isFiltering ? filteredCoins[indexPath.row].symbol
        : allCoinsList[indexPath.row].symbol
        selectedCoinPair = isFiltering ? filteredCoins[indexPath.row].symbol
        : allCoinsList[indexPath.row].symbol
        self.title = isFiltering ? filteredCoins[indexPath.row].symbol
        : allCoinsList[indexPath.row].symbol
        self.cryptoTV.reloadData()
        if !isFirstTime{
            self.disconnectRequest()
        }
        self.makeRequest()
        self.didTapped(nil)
//        self.didTapped(nil)
    }
    //MARK: - API Function
    
    func getSymbols() {
        Alamofire.request("https://api.binance.com/api/v1/exchangeInfo").responseData(queue: nil, completionHandler: { response in
            switch response.result {
                
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    self.coinDataModel =  try decoder.decode(CoinDataModel.self, from: data)
                    self.allCoinsList = self.coinDataModel.symbols
                    self.searchBar(self.coinSearchBar, textDidChange: "BTCUSDT")
                    self.tableView(self.cryptoTV, didSelectRowAt: IndexPath(row: 0, section: 0))
                } catch {
                    
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
//        Alamofire.request("https://api.binance.com/api/v1/exchangeInfo").responseDecodable(of: CoinDataModel.self) { response in
//            switch response.result {
//            case .success(let data):
//                self.coinDataModel = data
//                self.allCoinsList = data.symbols
//                //for inital setup
//                self.searchBar(self.coinSearchBar, textDidChange: "BTCUSDT")
//                self.tableView(self.cryptoTV, didSelectRowAt: IndexPath(row: 0, section: 0))
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
    
    //MARK: - Wrbsocket functions
    
    func makeRequest() {
//        var symbol = String()
//        for i in 0..<self.model.name.count {
//            if self.model.isSelected[i] {
//                symbol = self.model.name[i].rawValue.lowercased()
//            }
//        }
        let urlString =
        "wss://stream.binance.com:9443/ws/\(selectedCoinPair.lowercased())@depth"
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    func disconnectRequest() {
        socket.disconnect()
    } 
    
    
    //MARK: - Websocket delegate methods
    
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
            let decoder = JSONDecoder()
           if isFirstTime {
                    do {
                        self.buyAskModel = try decoder.decode(DepthDataModel.self, from: string.data(using: .utf8)!)
//                        print("Bid Price: ",buyAskModel.bids.first?.first as Any,"Bid Quantity: ",buyAskModel.bids.first?.last as Any)
//                        print("Ask Price: ",buyAskModel.asks.first?.first as Any,"Ask Quantity: ",buyAskModel.asks.first?.last as Any)
                        DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                            self.isFirstTime = false
                        })
//                        self.removeNoQuantities()
                    } catch {
                        print(error)
                    }
            } else {
                        do {
                            self.updateModel = try decoder.decode(DepthDataModel.self, from: string.data(using: .utf8)!)
//                            print("Bid Price: ",updateModel.bids.first?.first as Any,"Bid Quantity: ",updateModel.bids.first?.last as Any)
//                            print("Ask Price: ",updateModel.asks.first?.first as Any,"Ask Quantity: ",updateModel.asks.first?.last as Any)
                        } catch {
                            print(error)
                        }
            }
            self.bidsTV.reloadData()
            self.asksTV.reloadData()

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

    
}
var isDarkStyle : Bool = false
extension UIView {
    func elevate(_ radius: CGFloat) {
      layer.masksToBounds = false
      layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
      layer.shadowOffset = CGSize(width: -radius, height: radius)
        layer.shadowRadius = 1

      layer.shadowPath = UIBezierPath(rect: bounds).cgPath
      layer.shouldRasterize = true
      layer.rasterizationScale = UIScreen.main.scale
    }
    
    func border(colour : UIColor, width : Int) {
        layer.borderColor = colour.cgColor
        layer.borderWidth = CGFloat(width)
    }
    
    func changeDarkMode () {
        self.backgroundColor = isDarkStyle ? .black : .white
    }
}
extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

//struct Theme {
//    enum `Type` {
//        case light
//        case dark
//    }
//    let type: Type
//    let colors: UIColor
//}
//
//extension Theme : Equatable{
//    static let light = Theme(type: .light, colors: .white)
//    static let dark = Theme(type: .dark, colors: .green)
//}
//
//protocol Themeable: AnyObject {
//    func apply(theme: Theme)
//}
//class ThemeProvider {
//    static let shared = ThemeProvider()
//    var theme: Theme {
//        didSet {
//            UserDefaults.standard.set(theme == .dark, forKey: "isDark")
//            notifyObservers()
//        }
//    }
//    private var observers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
//
//    private init() {
//        self.theme = UserDefaults.standard.bool(forKey: "isDark") ? .dark : .light
//    }
//
//    func toggleTheme() {
//        theme = theme == .light ? .dark : .light
//    }
//
//    func register<Observer: Themeable>(observer: Observer) {
//        observer.apply(theme: theme)
//        self.observers.add(observer)
//    }
//
//    private func notifyObservers() {
//        DispatchQueue.main.async {
//            self.observers.allObjects
//                .compactMap({ $0 as? Themeable })
//                .forEach({ $0.apply(theme: self.theme) })
//        }
//    }
//}
