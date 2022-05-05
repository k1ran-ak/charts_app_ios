//
//  DrawImageViewController.swift
//  BidAsk
//
//  Created by admin on 3/23/22.
//

import UIKit

class DrawImageViewController: UIViewController {
    
    
    //MARK: - Outlets
    @IBOutlet weak var holderView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var eraseSwitch : UISwitch!
    
    @IBOutlet weak var shareButton: UIButton!
    //    @IBOutlet var drawingView: DrawingView!
    
    //MARK: - Local variables
    
    var newImage = UIImage()
    let line: CAShapeLayer! = CAShapeLayer()
    let linePath: UIBezierPath = UIBezierPath()
    var startingPoint : CGPoint!
    var endingPoint : CGPoint!
    var lastPoint : CGPoint!
    var currentLayer = CAShapeLayer()
    var currentPath = UIBezierPath()
    var isDrawing = true
    var eraseOn : Bool = false
    private let pencil = Pencil()
    private let mainImageView = UIImageView()
    let drawingView = DrawingView()
    let eraseSwitch2 = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = newImage
        self.title = "Draw and Share"
        self.eraseSwitch.setOn(false, animated: false)
        
//        self.imageView.addSubview(drawingView)
//        self.imageView.bringSubviewToFront(drawingView)
//        self.view.addSubview(eraseSwitch)
        self.drawingView.frame = self.imageView.frame
        self.holderView.addSubview(drawingView)
        
//        self.view.bringSubviewToFront(drawingView)
//        self.drawingView.frame = self.view.frame
        //        self.view.addSubview(mainImageView)
        //        self.view.bringSubviewToFront(mainImageView)
    }
    
    //MARK: - Button Actions
    @IBAction func switchAction(_ sender: Any) {
        self.eraseOn = !eraseOn
        self.eraseSwitch.setOn(eraseOn, animated: true)
        self.drawingView.isDrawing = !eraseOn
    }
    
    @IBAction func shareAction(_ sender: Any) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.isOpaque, 0.0)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        newImage = image ?? UIImage()
        let activityVC = UIActivityViewController(activityItems: [newImage as Any], applicationActivities: nil)
           activityVC.popoverPresentationController?.sourceView = self.view
           self.present(activityVC, animated: true, completion: nil)
    }
    
    
//    //MARK: - Touch Functions
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else {return}
//        lastPoint = touch.location(in: self.view)
//        // reset both objects so that every touch is a brand new layer and shape
//        self.view.layer.addSublayer(currentLayer)
//    }
//
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        if !self.drawingView.isDrawing, let layer = findLayer(in: touch) {
//            removeFromSuperLayer(from: layer)
//        }
//        let renderer = UIGraphicsImageRenderer(bounds: self.view.bounds)
//        let image = renderer.image { rendererContext in
//            self.view.layer.render(in: rendererContext.cgContext)
//        }
//        //        mainImageView.image = image
//    }
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        let currentPoint = touch.location(in: self.view)
//        if self.drawingView.isDrawing {
//            drawLine(from: lastPoint, to: currentPoint)
//            //                makeLineLayer(currentLayer, lineFromPointA: lastPoint, toPointB: currentPoint)
//        }
//        lastPoint = currentPoint
//    }
//
//    //MARK: - Other necessary functions
//    private func findLayer(in touch: UITouch) -> CAShapeLayer? {
//        let point = touch.location(in: self.view)
//        // check if any sublayers where added (drawings)
//        guard let sublayers = self.view.layer.sublayers else { return nil }
//
//        for layer in sublayers {
//            if let shapeLayer = layer as? CAShapeLayer,
//               let outline = shapeLayer.path?.copy(strokingWithWidth: pencil.outlineSize, lineCap: .butt, lineJoin: .round, miterLimit: 0),
//               outline.contains(point) == true {
//                return shapeLayer
//            }
//        }
//        return nil
//    }
//    private func removeFromSuperLayer(from layer: CALayer) {
//        if layer != self.view.layer {
//            if let superLayer = layer.superlayer {
//                removeFromSuperLayer(from: superLayer)
//                layer.removeFromSuperlayer()
//                currentPath.removeAllPoints()
//            }
//        }
//    }
//    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
//        currentPath.move(to: fromPoint)
//        currentPath.addLine(to: toPoint)
//        currentLayer.path = currentPath.cgPath
//        currentLayer.backgroundColor = UIColor.red.cgColor
//        currentLayer.strokeColor = pencil.color.cgColor
//        currentLayer.lineWidth = pencil.strokeSize
//        currentLayer.lineCap = .round
//        currentLayer.lineJoin = .round
//    }
}
struct Pencil {
    let color: UIColor = .red
    let strokeSize: CGFloat = 8
    let outlineSize: CGFloat = 12
}
