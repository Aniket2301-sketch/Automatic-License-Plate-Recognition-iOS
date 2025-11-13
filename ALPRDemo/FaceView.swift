import UIKit

class FaceView: UIView {

    var faceBoxes: NSMutableArray? = nil
    var frameSize: CGSize?  // camera frame size

    public func setFaceBoxes(faceBoxes: NSMutableArray) {
        self.faceBoxes = faceBoxes
        setNeedsDisplay()
    }

    public func setFrameSize(frameSize: CGSize) {
        self.frameSize = frameSize
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let faceBoxes = faceBoxes,
              let frameSize = frameSize else { return }

        context.beginPath()
        
        // Since preview is fit by height:
        let scale = bounds.height / frameSize.height
        let xOffset = (bounds.width - frameSize.width * scale) / 2
        let yOffset: CGFloat = 0

        for faceBox in (faceBoxes as NSArray as! [ALPRBox]) {
            let color = UIColor.green
            let string = faceBox.number ?? ""
            
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(2.0)
            
            // Scale ALPRBox coordinates to view coordinates
            let boxRect = CGRect(
                x: CGFloat(faceBox.x1) * scale + xOffset,
                y: CGFloat(faceBox.y1) * scale + yOffset,
                width: CGFloat(faceBox.x2 - faceBox.x1) * scale,
                height: CGFloat(faceBox.y2 - faceBox.y1) * scale
            )
            
            context.addRect(boxRect)
            
            // Draw plate number
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: color
            ]
            let textPoint = CGPoint(x: boxRect.minX + 5, y: max(boxRect.minY - 25, 0))
            string.draw(at: textPoint, withAttributes: attributes)
            
            context.strokePath()
        }
    }
}
