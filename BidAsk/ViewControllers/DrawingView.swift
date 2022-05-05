//
//  DrawingView.swift
//  BidAsk
//
//  Created by admin on 3/23/22.
//

import UIKit

class DrawingView: UIView {

        
        private var lastPoint: CGPoint = .zero
        private var currentPath = UIBezierPath()
        private var currentLayer: CAShapeLayer = CAShapeLayer()
        private let pencil = Pencil()
        private let canvasView = UIView()
         let mainImageView = UIImageView()
        
        var isDrawing: Bool = true
        
        override init(frame: CGRect) {
            super.init(frame: frame)
//            self.addSubview(mainImageView)
//            self.addSubview(canvasView)
//            self.bringSubviewToFront(canvasView)
            [mainImageView, canvasView].forEach {
                addSubview($0)
//                $0.pinToSuperViewEdges()
            }
        }
        
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
    }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            
            lastPoint = touch.location(in: self)
            if isDrawing {
                currentLayer = CAShapeLayer()
                currentPath = UIBezierPath()
                canvasView.layer.addSublayer(currentLayer)
            }
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            
            let currentPoint = touch.location(in: self)
            if isDrawing {
                drawLine(from: lastPoint, to: currentPoint)
            }
            lastPoint = currentPoint
        }
        
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            // this is to make sure that when the user touches the screen again
            // He works on a new layer, this way we get one layer one drawing.
            
            if !isDrawing, let layer = findLayer(in: touch) {
                removeFromSuperLayer(from: layer)
            }
            
            // Create and image representation of all layers in tempImageView
            let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
            let image = renderer.image { rendererContext in
                canvasView.layer.render(in: rendererContext.cgContext)
            }
            // The resulting image of rendering all layers of `canvasView` is saved in `mainImageView`
            mainImageView.image = image
        }
        
        private func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
            currentPath.move(to: fromPoint)
            currentPath.addLine(to: toPoint)
            
            currentLayer.path = currentPath.cgPath
            currentLayer.backgroundColor = UIColor.red.cgColor
            currentLayer.strokeColor = pencil.color.cgColor
            currentLayer.lineWidth = pencil.strokeSize
            currentLayer.lineCap = .round
            currentLayer.lineJoin = .round
        }
        
        private func findLayer(in touch: UITouch) -> CAShapeLayer? {
            let point = touch.location(in: self)

            // check if any sublayers where added (drawings)
            guard let sublayers = canvasView.layer.sublayers else { return nil }

            for layer in sublayers {
                if let shapeLayer = layer as? CAShapeLayer,
                    let outline = shapeLayer.path?.copy(strokingWithWidth: pencil.outlineSize, lineCap: .butt, lineJoin: .round, miterLimit: 0),
                    outline.contains(point) == true {
                    return shapeLayer
                }
            }
            
            return nil
        }
        
        private func removeFromSuperLayer(from layer: CALayer) {
            if layer != canvasView.layer {
                if let superLayer = layer.superlayer {
                    removeFromSuperLayer(from: superLayer)
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
