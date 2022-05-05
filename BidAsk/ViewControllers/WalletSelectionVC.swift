//
//  WalletSelectionVC.swift
//  BidAsk
//
//  Created by admin on 11/04/22.
//

import Foundation
import UIKit
import WalletConnectSwift

class WalletSelection : UIViewController {
    
    func connect() -> String {
        let wcUrl = WCURL(topic: UUID().uuidString,
            bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io/")!,
            key: try! randomKey())

        let clientMeta = Session.ClientMeta(name: "ExampleDemoApp",
            description: "WalletConnectDemo",
            icons: [],
            url: URL(string: "https://safe.gnosis.io")!)

        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString,
            peerMeta: clientMeta,
            chainId: ViewController.chainID)

        client = Client(delegate: self, dAppInfo: dAppInfo)

        print("WalletConnect URL: \(wcUrl.absoluteString)")

        try! client.connect(to: wcUrl)
        return wcUrl.absoluteString
    }
}

