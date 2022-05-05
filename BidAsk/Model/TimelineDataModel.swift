//
//  TimelineDataModel.swift
//  BidAsk
//
//  Created by Mac on 10/03/22.
//

import Foundation
// MARK: - TimelineDataModel
class TimelineDataModel: Codable {
    let timelineDataModelE: String
    let e: Int
    let s: String
    let timeline: Timeline

    enum CodingKeys: String, CodingKey {
        case timelineDataModelE = "e"
        case e = "E"
        case s = "s"
        case timeline = "k"
    }
    init () {
        self.e = 0
        self.s = ""
        self.timeline = Timeline()
        self.timelineDataModelE = ""
    }
  
}

// MARK: - K
class Timeline: Codable {
    let startTime: Int
    let closeTime: Int
    let s: String
    let interval: String
    let f: Int
    let l: Int
    let open: String
    let close: String
    let high: String
    let low: String
    let volume: String
    let n: Int
    let x: Bool
    let kQ: String
    let v: String
    let q: String
    let b: String

    enum CodingKeys: String, CodingKey {
        case startTime = "t"
        case closeTime = "T"
        case s = "s"
        case interval = "i"
        case f = "f"
        case l = "L"
        case open = "o"
        case close = "c"
        case high = "h"
        case low = "l"
        case volume = "v"
        case n = "n"
        case x = "x"
        case kQ = "q"
        case v = "V"
        case q = "Q"
        case b = "B"
    }
    init () {
        self.startTime = 0
        self.closeTime = 0
        self.s = ""
        self.interval = ""
        self.f = 0
        self.l = 0
        self.close = ""
        self.high = ""
        self.open = ""
        self.low = ""
        self.n = 0
        self.x = false
        self.kQ = ""
        self.v = ""
        self.q = ""
        self.b = ""
        self.volume = ""
    }
}
enum Interval : String{
    case onemin
    case threemin
    case fivemin
    case fifteenmin
    case thirthymin
    case onehour
    case twohour
    case fourhour
    case sixhour
    case eighthour
    case twelevehour
    case oneday
    case threeday
    case oneweek
    case onemonth
    
    var description: String {
            switch self {
            
            case .onemin:
                return "1m"
            case .threemin:
                return "3m"
            case .fivemin:
                return "5m"
            case .fifteenmin:
                return "15m"
            case .thirthymin:
               return "30m"
            case .onehour:
                return "1h"
            case .twohour:
                return "2h"
            case .fourhour:
                return "4h"
            case .sixhour:
                return "6h"
            case .eighthour:
                return "8h"
            case .twelevehour:
                return "12h"
            case .oneday:
                return "1d"
            case .threeday:
                return "3d"
            case .oneweek:
                return "1w"
            case .onemonth:
                return "1M"
            }
    
}
    var intervalValue: Int {
            switch self {
            
            case .onemin:
                return 1
            case .threemin:
                return 3
            case .fivemin:
                return 5
            case .fifteenmin:
                return 15
            case .thirthymin:
               return 30
            case .onehour:
                return 1
            case .twohour:
                return 2
            case .fourhour:
                return 4
            case .sixhour:
                return 6
            case .eighthour:
                return 8
            case .twelevehour:
                return 12
            case .oneday:
                return 1
            case .threeday:
                return 3
            case .oneweek:
                return 1
            case .onemonth:
                return 1
            }
    
}
    var text : String {
        switch self {
        case .onemin:
            return "1 minute"
        case .threemin:
            return "3 minutes"
        case .fivemin:
            return "5 minutes"
        case .fifteenmin:
           return "15 minutes"
        case .thirthymin:
           return "30 minutes"
        case .onehour:
            return "1 hour"
        case .twohour:
           return "2 hours"
        case .fourhour:
           return "4 hours"
        case .sixhour:
           return "6 hours"
        case .eighthour:
           return "8 hours"
        case .twelevehour:
           return "12 hours"
        case .oneday:
           return "1 day"
        case .threeday:
           return "3 days"
        case .oneweek:
            return "1 week"
        case .onemonth:
           return "1 month"
        }
    }
}
enum TimelineAPIDataModelElement: Codable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(TimelineAPIDataModelElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TimelineAPIDataModelElement"))
    }
    var DoubleValue : Double {
        switch self {
        case .integer(let int):
            return Double(int)
        case .string(let string):
            return Double(string) ?? 0.0
        }
    }
}
typealias TimelineAPIDataModel = [[TimelineAPIDataModelElement]]
