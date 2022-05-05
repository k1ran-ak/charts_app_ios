//
//  PriceDataModel.swift
//  BidAsk
//
//  Created by Mac on 11/03/22.
//

// MARK: - PriceDataModel
class PriceDataModel: Codable {
    let priceDataModelE: String
    let e: Int
    let s: String
    let priceDataModelT: Int
    let price: String
    let q: String
    let b: Int
    let a: Int
    let t: Int
    let priceDataModelM: Bool
    let m: Bool

    enum CodingKeys: String, CodingKey {
        case priceDataModelE = "e"
        case e = "E"
        case s = "s"
        case priceDataModelT = "t"
        case price = "p"
        case q = "q"
        case b = "b"
        case a = "a"
        case t = "T"
        case priceDataModelM = "m"
        case m = "M"
    }
    init() {
        self.priceDataModelE = ""
        self.e = 0
        self.s = ""
        self.priceDataModelT = 0
        self.price = ""
        self.q = ""
        self.b = 0
        self.a = 0
        self.t = 0
        self.priceDataModelM = false
        self.m = false
    }

  
}
