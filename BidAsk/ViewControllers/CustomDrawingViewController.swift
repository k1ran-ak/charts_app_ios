//
//  CustomDrawingViewController.swift
//  BidAsk
//
//  Created by admin on 3/28/22.
//

import UIKit
import QuartzCore

class CustomDrawingViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource{
    
    
    //MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sideBarTV: UITableView!
    @IBOutlet weak var contentView: DemoView!
    
    //MARK: - Local variables
    let width: CGFloat = 240.0
    let height: CGFloat = 160.0
    var image = UIImage()
    let drawingView = DrawingView()
    var initialSelection = [false,false,false,false,false,false,false]
    //    let demoView = DemoView(frame: CGRect(x: self.view.frame.size.width/2 - self.width/2,y: self.view.frame.size.height/2 - self.height/2,width: self.width,height: self.height))
    //MARK: - Class functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentView.isMultipleTouchEnabled = true
        self.contentView.isExclusiveTouch = true
        self.sideBarTV.delegate = self
        self.sideBarTV.dataSource = self
        self.imageView.image = image
//        self.drawingView.frame = self.contentView.frame
//        self.contentView.addSubview(drawingView)
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //MARK: - Tableview functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem1") else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem2") else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else if indexPath.row == 2{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem3")else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else if indexPath.row == 3 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem4")else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else if indexPath.row == 4{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem5")else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else if indexPath.row == 5{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem6")else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "sideBarItem7")else     {return UITableViewCell()}
            if initialSelection[indexPath.row] {
                cell.border(colour: .blue, width: 2)
            } else {
                cell.border(colour: .blue, width: 0)
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) else {return}
        
        if !self.initialSelection[indexPath.row] && self.initialSelection.contains(where: {$0 == true}) {
            guard let index = self.initialSelection.firstIndex(where: {$0 == true}) else {return}
            self.initialSelection[index] = false
            contentView.shapeFunctionFalse(index)
        }
        self.initialSelection[indexPath.row] = !self.initialSelection[indexPath.row]
        if self.initialSelection[indexPath.row] {
        contentView.shapeFunction(indexPath.row)
        } else {
            contentView.shapeFunctionFalse(indexPath.row)
        }
        tableView.reloadData()
    }
    
}

class DemoView : UIView {
    //MARK: - Local variables
    var path: UIBezierPath!
    var arrayTouches = [CGPoint]()
    let shapeLayer = CAShapeLayer()
    var drawRectange : Bool = false
    var drawTriangle : Bool = false
    var drawCircle : Bool = false
    var drawText : Bool = false
    var moveLayer : Bool = false
    var deleteLayer : Bool = false
    var drawLine : Bool = false
    let pencil = Pencil()
    var isDrawing: Bool = true
    var pointsArray = [CGPoint]()
    /// Initilisation of view with frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.darkGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func shapeFunction(_ index : Int) {
        self.arrayTouches.removeAll()
        if index == 0 {
            self.drawRectange = true
        } else if index == 1 {
            self.drawTriangle = true
        } else if index == 2 {
            self.drawCircle = true
        } else if index == 3 {
            self.drawText = true
        } else if index == 4 {
            self.moveLayer = true
        } else if index == 6 {
            self.drawLine = true
        }else if index == 5{
            self.isDrawing = false
        }
    }
    func shapeFunctionFalse(_ index : Int) {
        if index == 0 {
            self.drawRectange = false
        } else if index == 1 {
            self.drawTriangle = false
        } else if index == 2 {
            self.drawCircle = false
        } else if index == 3 {
            self.drawText = false
        } else if index == 4 {
            self.moveLayer = false
        } else if index == 6 {
            self.drawLine = false
        }else if index == 5{
            self.isDrawing = true
        }
    }
    //MARK: - Touch functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            print("touched at: ",location)
            arrayTouches.append(location)
        }
        if isDrawing {
        self.simpleShapeLayer()
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        print("touch ended at: ",location)
       
        if !isDrawing, let layer = findLayer(in: touch) {
            removeFromSuperLayer(from: layer)
            self.pointsArray.removeAll()
        }
        if !isDrawing, let layer = findOtherLayer(in: touch) {
            removeFromSuperLayer(from: layer)
        }
        setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        print("Moving at: ",point)
        guard let layer = findLayer(in: touch) else {return}
        guard let path = layer.path else { return }
        
        if moveLayer && path.contains(touch.location(in: self)) {
//            self.moveLayer = false
            layer.position = touch.location(in: self)
//            print("Moved to: ",touch.location(in: self))
//            var translation = CGAffineTransform(translationX: point.x,y: point.y)
//            let movedPath = path.copy(using: &translation)
//            self.shapeLayer.path = movedPath
//            self.layer.addSublayer(shapeLayer)
        }
        setNeedsDisplay()
    }
    func removeFromSuperLayer(from layer: CALayer) {
        if layer != self.layer {
            if let superLayer = layer.superlayer {
                removeFromSuperLayer(from: superLayer)
                layer.removeFromSuperlayer()
            }
        }
    }
   
    
    //MARK: - Custom shapes functions
    
     func findLayer(in touch: UITouch) -> CAShapeLayer? {
        let point = touch.location(in: self)
        // check if any sublayers where added (drawings)
         guard let sublayers = self.layer.sublayers else { return nil }
        for layer in sublayers {
            if let shapeLayer = layer as? CAShapeLayer,
                let outline = shapeLayer.path?.copy(strokingWithWidth: pencil.outlineSize, lineCap: .butt, lineJoin: .round, miterLimit: 0),
                outline.contains(point) == true {
                return shapeLayer
            }
        }
        return nil
    }
    
    func findOtherLayer(in touch: UITouch) -> CATextLayer? {
        let point = touch.location(in: self)
        // check if any sublayers where added (drawings)
        guard let sublayers = self.layer.sublayers else { return nil }
        for layer in sublayers {
            if let textLayer = layer as? CATextLayer,
               textLayer.contains(point) == true {
                return textLayer
            }
        }
        return nil
    }
    
    func createRectangle() -> UIBezierPath{
//        self.drawRectange = false
        if self.arrayTouches.count >= 4 {
            // Initialize the path.
            let path = UIBezierPath()
            // Specify the point that the path should start get drawn.
            path.move(to: arrayTouches[arrayTouches.count - 4])
            // Create a line between the starting point and the second side of the view.
            path.addLine(to: arrayTouches[arrayTouches.count - 3])
            // Create the bottom line 2nd to 3rd.
            path.addLine(to: arrayTouches[arrayTouches.count - 2])
            // Create the 3rd to 4th.
            path.addLine(to: arrayTouches[arrayTouches.count - 1])
            // Close the path. This will create the last line automatically.
            path.close()
            return path
        } else {
            return UIBezierPath()
        }
    }
    
//    override func draw(_ rect: CGRect) {
//        //        self.createRectangle()
//
//        //        UIColor.orange.setFill()
//        //           path.fill()
//        //
//        //           // Specify a border (stroke) color.
//        //           UIColor.purple.setStroke()
//        //           path.stroke()
//    }
    
    func createTriangle() -> UIBezierPath{
//        self.drawTriangle = false
        if arrayTouches.count >= 3 {
        let path = UIBezierPath()
            path.move(to: arrayTouches[arrayTouches.count - 3])
        path.addLine(to: arrayTouches[arrayTouches.count - 2])
        path.addLine(to: arrayTouches[arrayTouches.count - 1])
        path.close()
        return path
        } else{ return UIBezierPath()}
    }
    
    func createOval() {
        path = UIBezierPath()
        path = UIBezierPath(ovalIn: self.bounds)
    }
    
    func createCircle() -> UIBezierPath{
//        self.drawCircle = false
        if arrayTouches.count >= 2 {
            var path = UIBezierPath()
            let x = arrayTouches.first!.x
            let y = arrayTouches.first!.y
            let radius = distance(arrayTouches[arrayTouches.count - 0], arrayTouches[arrayTouches.count - 1])
             path = UIBezierPath(ovalIn: CGRect(x: x,
                                               y: y,
                                               width: radius,
                                               height: radius))
            return path
        } else {
            return UIBezierPath()
        }
    }
    func createPoints() -> UIBezierPath{
        if arrayTouches.count >= 1 {
            var path = UIBezierPath()
            guard let x = arrayTouches.first?.x else {return UIBezierPath()}
            guard let y = arrayTouches.first?.y else {return UIBezierPath()}
            self.pointsArray.append(arrayTouches.first!)
            path = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: 10, height: 10))
            return path
        }
        else {return UIBezierPath()}
    }
    ///Distance between two points
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = abs(a.x - b.x)
        let yDist = abs(a.y - b.y)
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    func simpleShapeLayer() {
       var newPath = UIBezierPath()
        if drawRectange {
             newPath = createRectangle()
        } else if drawTriangle{
            newPath = createTriangle()
        } else if drawCircle {
            newPath = createCircle()
        } else if drawText{
            self.createTextLayer()
            return
        } else if drawLine{
            newPath = createPoints()
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = newPath.cgPath
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.blue.cgColor
            shapeLayer.lineWidth = 3.0
            self.layer.addSublayer(shapeLayer)
            //Since line requires two points to draw
            if pointsArray.count >= 2 {
                newPath = createLine()
            }
        }
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = newPath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.blue.cgColor
        shapeLayer.lineWidth = 3.0
        self.layer.addSublayer(shapeLayer)
//        self.arrayTouches.removeAll()
    }
    
    func maskVsSublayer() {
//        self.createTriangle()
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.yellow.cgColor
        self.layer.mask = shapeLayer
    }
    func createLine() -> UIBezierPath{
        let path = UIBezierPath()
        let pointA = minus(lhs:  pointsArray[pointsArray.count - 2], rhs: CGPoint(x: 5, y: 5))
        let pointB = minus(lhs:  pointsArray[pointsArray.count - 1], rhs: CGPoint(x: 5, y: 5))
        path.move(to: pointA)
        path.addLine(to: pointB)
//        self.drawLine = false
        self.pointsArray.removeAll()
        return path
    }
     func minus (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    func createTextLayer() {
//        self.drawText = false
        let textLayer = CATextLayer()
        textLayer.string = "WOW!\nThis is text on a layer!"
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.font = UIFont(name: "Avenir", size: 15.0)
        textLayer.fontSize = 15.0
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.backgroundColor = UIColor.orange.cgColor
        textLayer.frame = CGRect(x: 0.0, y: self.frame.size.height/2 - 20.0, width: self.frame.size.width, height: 40.0)
        textLayer.contentsScale = UIScreen.main.scale
        self.layer.addSublayer(textLayer)
    }
}
