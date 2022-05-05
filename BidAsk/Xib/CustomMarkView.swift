//
//  CustomMarkView.swift
//  BidAsk
//
//  Created by Mac on 11/03/22.
//

import UIKit
import Charts
import Starscream

class CustomMarkerView: MarkerView {
        
    
    //MARK: - Outlets
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var holderStackView: UIStackView!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var closeLabel: UILabel!
    @IBOutlet weak var openLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    //MARK: - Class functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    private func initUI() {
        Bundle.main.loadNibNamed("CustomMarkerView", owner: self, options: nil)
        self.addSubview(holderView)
        self.frame = CGRect(x: 0, y: 0, width: 60, height: 80)
        self.offset = CGPoint(x: -(self.frame.width*2), y: -(self.frame.height))
        self.layer.cornerRadius = 5
    }
    func greenTextColour() {
        self.lowLabel.textColor = .green
        self.highLabel.textColor = .green
        self.closeLabel.textColor = .green
        self.openLabel.textColor = .green
    }
    func redTextColour() {
        self.lowLabel.textColor = .red
        self.highLabel.textColor = .red
        self.closeLabel.textColor = .red
        self.openLabel.textColor = .red
        
    }
}
