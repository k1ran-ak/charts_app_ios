//
//  DepthDataModel.swift
//  BidAsk
//
//  Created by Mac on 09/03/22.
//
import Foundation
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let depthDataModel = try? newJSONDecoder().decode(DepthDataModel.self, from: jsonData)
// MARK: - DepthDataModel
class DepthDataModel: Codable {
    let depthDataModelE: String
    let e: Int
    let s: String
    let u: Int
    let depthDataModelU: Int
    var bids: [[String]]
    var asks: [[String]]

    enum CodingKeys: String, CodingKey {
        case depthDataModelE = "e"
        case e = "E"
        case s = "s"
        case u = "U"
        case depthDataModelU = "u"
        case bids = "b"
        case asks = "a"
    }
    
    init () {
        self.depthDataModelE = ""
        self.e = 0
        self.s = ""
        self.u = 0
        self.depthDataModelU = 0
        self.bids = []
        self.asks = []
    }
}

extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}


