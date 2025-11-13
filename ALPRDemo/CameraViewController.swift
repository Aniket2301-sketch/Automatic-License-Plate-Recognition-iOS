import UIKit
import AVFoundation
import CoreData

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
   
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var faceView: FaceView!
    @IBOutlet weak var resultView: UIView!
    
    
    @IBOutlet weak var enrolledImage: UIImageView!
    @IBOutlet weak var identifiedImage: UIImageView!
    @IBOutlet weak var identifiedLbl: UILabel!
    @IBOutlet weak var similarityLbl: UILabel!
    @IBOutlet weak var livenessLbl: UILabel!
    @IBOutlet weak var yawLbl: UILabel!
    @IBOutlet weak var rollLbl: UILabel!
    @IBOutlet weak var pitchLbl: UILabel!
    
    var recognized = false

    var cameraLens_val = 0
    var livenessThreshold = Float(0)
    var identifyThreshold = Float(0)

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: ViewController.CORE_DATA_NAME)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        cameraView.translatesAutoresizingMaskIntoConstraints = true
        cameraView.frame = view.bounds
        
        faceView.translatesAutoresizingMaskIntoConstraints = true
        faceView.frame = view.bounds

        resultView.translatesAutoresizingMaskIntoConstraints = true
        resultView.frame = view.bounds

        let defaults = UserDefaults.standard
        cameraLens_val = defaults.integer(forKey: "camera_lens")
        livenessThreshold = defaults.float(forKey: "liveness_threshold")
        identifyThreshold = defaults.float(forKey: "identify_threshold")

        startCamera()
    }
    
    func startCamera() {
        var cameraLens = AVCaptureDevice.Position.front
        if(cameraLens_val == 0) {
            cameraLens = AVCaptureDevice.Position.back
        }
        
        // Create an AVCaptureSession
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Create an AVCaptureDevice for the camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraLens) else { return }
        guard let input = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Create an AVCaptureVideoDataOutput
        let videoOutput = AVCaptureVideoDataOutput()

        // Set the video output's delegate and queue for processing video frames
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))

        // Add the video output to the session
        session.addOutput(videoOutput)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        cameraView.layer.addSublayer(previewLayer)

        // Start the session
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if(recognized == true) {
            return
        }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let image = UIImage(cgImage: cgImage!)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)

        // Rotate and flip the image
        var capturedImage = image.rotate(radians: .pi/2)
        if(cameraLens_val == 1) {
            capturedImage = capturedImage.flipHorizontally()
        }
        
        let alprBoxes = ALPRSDK.processImage(capturedImage);
//       
        DispatchQueue.main.sync {
            self.faceView.setFrameSize(frameSize: capturedImage.size)
            self.faceView.setFaceBoxes(faceBoxes: alprBoxes)
        }
    }
    
    @IBAction func done_clicked(_ sender: Any) {
        self.resultView.showView(isHidden_: false)
        recognized = false
    }
    
}

extension UIView {
    
    func showView(isHidden_: Bool) {
        
        if isHidden_ {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 1.0
            }, completion: {_ in
                self.isHidden = false
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0.0
            }, completion: {_ in
                self.isHidden = true
            })
        }
    }
}
