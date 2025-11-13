import UIKit
import AVFoundation
import CoreData

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    static let CORE_DATA_NAME = "Model"
    static let ENTITIES_NAME = "Person"
    static let ATTRIBUTE_NAME = "name"
    static let ATTRIBUTE_FACE = "face"
    static let ATTRIBUTE_TEMPLATES = "templates"

    @IBOutlet weak var warningLbl: UILabel!
    
    @IBOutlet weak var enrollBtnView: UIView!
    @IBOutlet weak var identifyBtnView: UIView!
  
    @IBOutlet weak var imageView: UIImageView!
    
    
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
         var ret = ALPRSDK.setActivation("akxRJanttIzX+ddPyyKIXSYjtmGbrCO+zFn+7kvvIGRVJKaaOjZVWfi15a6Z1CCX5oR0aCGyD664" +
                                         "7KC6xbA4uK2xDw7g9W6M7QjS5LGfJgplEO45XqE3PgepmdqYiRFEl5sw+Xe+SWmfuOu8xyUwBD37" +
                                         "m2RoQ6TgCnBJ9rxYFM9MNxsLUrlBuKP5J8r/aZg5vFbotvLqXHI4enn8Lzva2lF6QYo0wMBhfus6" +
                                         "cY8fWzDnFvCvleLXHHGWCRYs0KLj37eCUAxVWuoO7luagiRoh0sFabCEtQx4GZf11ofcpqr8v7BO" +
                                         "j3PbBeba3PTbGgOoSvE7NKmwZTdv9uBRtK+LdQ==")
        
        if(ret == SDK_SUCCESS.rawValue) {
            ret = ALPRSDK.initSDK()
        }
        
        if(ret != SDK_SUCCESS.rawValue) {
            warningLbl.isHidden = false
            
            if(ret == SDK_LICENSE_KEY_ERROR.rawValue) {
                warningLbl.text = "Invalid license!"
            } else if(ret == SDK_LICENSE_APPID_ERROR.rawValue) {
                warningLbl.text = "Invalid license!"
            } else if(ret == SDK_LICENSE_EXPIRED.rawValue) {
                warningLbl.text = "License expired!"
            } else if(ret == SDK_NO_ACTIVATED.rawValue) {
                warningLbl.text = "No activated!"
            } else if(ret == SDK_INIT_ERROR.rawValue) {
                warningLbl.text = "Init error!"
            }
        }
        
        SettingsViewController.setDefaultSettings()
        
    }
    
    @IBAction func enroll_touch_down(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.enrollBtnView.backgroundColor = UIColor(named: "clr_main_button_bg2") // Change to desired color
        }
    }
    
    @IBAction func enroll_touch_cancel(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.enrollBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }
    }
    
    @IBAction func enroll_clicked(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.enrollBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func identify_touch_down(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "clr_main_button_bg2") // Change to desired color
        }
    }
    
    @IBAction func identify_touch_up(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }
    }
    
    @IBAction func identify_clicked(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }
        
        performSegue(withIdentifier: "camera", sender: self)
    }
 
    
    @IBAction func brand_clicked(_ sender: Any) {
        let webURL = URL(string: "https://kby-ai.com")
        UIApplication.shared.open(webURL!, options: [:], completionHandler: nil)
    }
    
    func drawALPRBoxes(on image: UIImage, boxes: [ALPRBox]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let renderedImage = renderer.image { context in
            // Draw the original image first
            image.draw(at: .zero)
            
            // Drawing context
            let ctx = context.cgContext
            ctx.setLineWidth(2.0)
            
            for box in boxes {
                let rect = CGRect(
                    x: CGFloat(box.x1),
                    y: CGFloat(box.y1),
                    width: CGFloat(box.x2 - box.x1),
                    height: CGFloat(box.y2 - box.y1)
                )
                
                // Draw rectangle
                ctx.setStrokeColor(UIColor.green.cgColor)
                ctx.stroke(rect)
                
                // Draw text (plate number)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 20),
                    .foregroundColor: UIColor.green
                ]
                
                let textPoint = CGPoint(x: rect.minX + 5, y: max(rect.minY - 25, 0))
                box.number.draw(at: textPoint, withAttributes: attributes)
            }
        }
        
        return renderedImage
    }

    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
        dismiss(animated: true, completion: nil)
        
        if let pickedImage = info[.originalImage] as? UIImage {
            
            let processImage = pickedImage.fixOrientation()
            let alprBoxes = ALPRSDK.processImage(processImage) as! [ALPRBox];
            
            let imageWithBoxes = drawALPRBoxes(on: processImage, boxes: alprBoxes)
            
            imageView.image = imageWithBoxes
        } else {
            print("No image found")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

