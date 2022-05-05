
import Foundation

// MARK: - CoinDataModel
class CoinDataModel: Codable {
    let timezone: String
    let serverTime: Int
    let symbols: [Symbol]

    enum CodingKeys: String, CodingKey {
        case timezone = "timezone"
        case serverTime = "serverTime"
        case symbols = "symbols"
    }

    init(){
        self.timezone = ""
        self.serverTime = 0
        self.symbols  = [Symbol]()
    }
}



// MARK: - Symbol
class Symbol: Codable {
    let symbol: String
    var isSelected : Bool? = false
    

    enum CodingKeys: String, CodingKey {
        case symbol = "symbol"
        case isSelected
       
    }
    init () {
        self.symbol = ""
        self.isSelected = false
    }

}


