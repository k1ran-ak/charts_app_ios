//
//  CryptoModel.swift
//  BidAsk
//
//  Created by Mac on 09/03/22.
//

import Foundation

class Crypto {
    var name : [CryptoNames]
    var isSelected : [Bool]
    init () {
        self.name = []
        self.isSelected = []
    }
    init (name : [CryptoNames], _ isSelected : [Bool]) {
        self.name = name
        self.isSelected = isSelected
    }
}

enum CryptoNames : String {
    case BNBBTC
    case ETHUSDT
    case BNBUSDT
    case MATICUSDT
    case SOLUSDT
    case ADAUSDT
    case LUNAUSDT
}
