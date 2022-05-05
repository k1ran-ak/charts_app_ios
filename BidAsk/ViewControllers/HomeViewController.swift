//
//  HomeViewController.swift
//  BidAsk
//
//  Created by admin on 3/16/22.
//

import UIKit

class HomeViewController: UIViewController, UICollectionViewDataSource  , UITableViewDataSource ,UICollectionViewDelegateFlowLayout{
 
    

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionHolderView: UIView!
    @IBOutlet weak var topCurvedView: UIView!
    @IBOutlet weak var imageCV: UICollectionView!
    @IBOutlet weak var cryptoTV: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        // Do any additional setup after loading the view.
        self.imageCV.dataSource = self
        self.imageCV.delegate = self
        self.imageCV.isPagingEnabled = true
        self.cryptoTV.dataSource = self
    }
    
    func initViews(){
        topCurvedView.cornerRadius(15)
        scrollView.cornerRadius(15)
        topCurvedView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        scrollView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        self.imageCV.scrollToItem(at: indexPath, at: [], animated: false)
//    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCVC", for: indexPath) as! ImageCVC
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width - 40, height: 90)
    }
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC", for: indexPath)
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC1", for: indexPath)
            return cell
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC2", for: indexPath)
            return cell
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC3", for: indexPath)
            return cell
        } else if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC4", for: indexPath)
            return cell
        } else if indexPath.row == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC5", for: indexPath)
            return cell
        }else if indexPath.row == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC6", for: indexPath)
            return cell
        }else if indexPath.row == 7 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC7", for: indexPath)
            return cell
        }else if indexPath.row == 8 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC8", for: indexPath)
            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoPricesTVC9", for: indexPath)
            return cell
        }
        
    }

}
class CryptoPricesTVC : UITableViewCell{
    
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var cryptoNameLabel: UILabel!
    @IBOutlet weak var lastPriceLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var percentageHolderView: UIView!
    
    
}
class CryptoPricesTVC1 : UITableViewCell {
    
}

class ImageCVC : UICollectionViewCell {
    @IBOutlet weak var holderView: UIView!
    
    @IBOutlet weak var bannerImageView: UIImageView!
   
}
extension UIView {
    func cornerRadius (_ radius : CGFloat) {
        self.layer.cornerRadius = radius
    }
    
    func isRounded (_ bool: Bool) {
        if bool {
            self.layer.cornerRadius = self.frame.height/2
        }
    }
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        self.layer.masksToBounds = true
        }
    func elevate(radius : CGFloat){
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = radius

        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}


