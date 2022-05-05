//
//  BuyAskTVC.swift
//  BidAsk
//
//  Created by Mac on 09/03/22.
//

import UIKit

class BuyAskTVC: UITableViewCell {

    
    //MARK: - Outlets
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.priceLabel.maxLength(length: 8)
        // Initialization code
    }


}
extension UILabel {
    func maxLength(length : Int) {
        guard let str = self.text else {return}
        let nsString = str as NSString
        if nsString.length >= length
        {
            self.text = nsString.substring(with: NSRange(location: 0, length: nsString.length > length ? length : nsString.length))
        }
    }
   
}
