//
//  ViewController.swift
//  TripGIF
//
//  Created by Jennifer K. on 2016/10/30.
//  Copyright © 2016年 TingYuKuo. All rights reserved.
//

// lilycheng84
//Wei10google


import UIKit
import GoogleMaps
import CoreLocation
import Photos
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class MapViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var mapView: GMSMapView!
    var subView: UIView!
    var locationManager = CLLocationManager()
    var myLat: String=""
    var myLong: String=""
    var lat = CLLocationDegrees()
    var long = CLLocationDegrees()
    var senderId = String()
    
    override func viewDidLoad() {
        // Location Manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // 取得地理位置權限
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest; // 設定座標精準度
        locationManager.startUpdatingLocation()
        

        
        // 新增mapuser到firebase
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if let err:Error = error {
                print(err.localizedDescription)
                return
            }
            // 取得代表目前的使用者的id
            self.senderId = ((FIRAuth.auth()?.currentUser?.uid)!)
            print("senderId = \(self.senderId)")
            // 新增user資訊到firebase的mapuser欄位
            let newUser = FIRDatabase.database().reference().child("mapuser").childByAutoId()
            let newUserData = ["name":"testuser","latitude": self.myLat,"longitude": self.myLong]
            newUser.setValue(newUserData)
            })
        // 開始讀取firebase目前有的使用者地理位置等資訊
        observeLocation()
        // 設置Google Map
        setupMap()

        DispatchQueue.main.async { () -> Void in
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 設置Google Map的基本設定
    func setupMap(){
        let camera = GMSCameraPosition.camera(withLatitude: 20,longitude: 120, zoom: 3)
        subView = UIView(frame: CGRect(x:0,y:0,width: view.bounds.size.width,height:400))
        subView.backgroundColor = UIColor.blue
        mapView = GMSMapView.map(withFrame: subView.bounds, camera: camera)
        mapView.settings.compassButton = true
        self.view.addSubview(subView)
        subView.addSubview(mapView)
    }
    // 刷新firebase中的目前使用者的地理位置資訊
    func refreshLocation() {
        let prntRef  = FIRDatabase.database().reference().child("mapuser").child((FIRAuth.auth()?.currentUser?.uid)!)
        prntRef.updateChildValues(["latitude": self.myLat])
        prntRef.updateChildValues(["longitude": self.myLong])
    }
    // 按下refresh按鈕時，執行清除地圖上的所有marker，並放上新的marker，來製造使用者移動的效果
    @IBAction func updateLocation(){
        mapView.clear()
        observeLocation()
    }
    //  偵測裝置目前的GPS位置
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let curLocation:CLLocation = locations[0]

        lat = curLocation.coordinate.latitude
        long = curLocation.coordinate.longitude
        print("latitude = \(lat)")
        print("longitude = \(long)")
        //  將經緯度轉成字串
        myLat = String(describing: lat)
        myLong = String(describing: long)
        //  只要位置有變動，就刷新firebase中使用者的經緯度資料
        refreshLocation()
    }
    //  
    @IBAction func choosePicture(sender: UIButton) {
        let picController = UIImagePickerController()
        picController.delegate = self
        picController.allowsEditing = true
        picController.sourceType = .photoLibrary
        let alertController = UIAlertController(title: "Add picture", message: "Choose From",preferredStyle: UIAlertControllerStyle.actionSheet)
        
        
        let cameraController = UIAlertAction(title: "Camera", style: .default, handler: { action in picController.sourceType = .camera
            self.present(picController, animated: true, completion: nil)
        })
        
        let photoLibraryController = UIAlertAction(title: "Photos Library", style: .default, handler: { action in
            picController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(picController, animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive,handler: nil)
        
        alertController.addAction(cameraController)
        alertController.addAction(photoLibraryController)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        var newImage = UIImage()
        
        print(info["UIImagePickerControllerOriginalImage"] ?? "NO IMAGE")
        print(info["UIImagePickerControllerReferenceURL"] ?? "NO URL")
        
        let imageUrl = info["UIImagePickerControllerReferenceURL"]
        let asset = PHAsset.fetchAssets(withALAssetURLs: [imageUrl as! URL], options: nil).firstObject! as PHAsset
        if((asset.location) != nil){
            let latitude = asset.location?.coordinate.latitude
            let longitude = asset.location?.coordinate.longitude
            
            //print("latitude:", latitude)
            //print("longitude:",longitude)
            //print("Creation Date: " + String(describing: asset.creationDate))
            
            newImage = ResizeImage(image: image!, targetSize: CGSize(width: 120, height:120))
            newImage = cropToBounds(image: newImage, width: 80, height: 80)
            newImage = maskRoundedImage(image: newImage, radius: 5, borderWidth: 0)
            let marker = GMSMarker()
            
            
            marker.position = CLLocationCoordinate2DMake(latitude!, longitude!)
            marker.map = mapView
            marker.icon = newImage
            
            let camera = GMSCameraPosition.camera(withLatitude: latitude!, longitude: longitude!, zoom: 6)
            mapView.animate(to: camera)
            
            picker.dismiss(animated: true, completion: nil)

        }else{  // 如果照片沒有地理位置
            print("沒有地理位置")
            picker.dismiss(animated: true, completion: nil)
            // 建立一個提示框
            let alertController = UIAlertController(
                title: "提示",
                message: "照片沒有地理位置資訊，無法新增照片，請開啟GPS定位再進行拍照",
                preferredStyle: .alert)
            
            // 建立[確認]按鈕
            let okAction = UIAlertAction(
                title: "確認",
                style: .default,
                handler: {
                    (action: UIAlertAction!) -> Void in
            })
            alertController.addAction(okAction)
            
            // 顯示提示框
            self.present(
                alertController,
                animated: true,
                completion: nil)
        }
    }
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        //        let rect = CGRect(x:0, y:0, width:newSize.width, height:newSize.height)
        let rect = CGRect(x:0, y:0, width:newSize.width, height:newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect = CGRect(x:posX, y:posY, width:cgwidth, height:cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    
    func maskRoundedImage(image: UIImage, radius: Float, borderWidth: Float) -> UIImage {
        let imageView: UIImageView = UIImageView(image: image)
        var layer: CALayer = CALayer()
        layer = imageView.layer
        let myColor : UIColor = UIColor.white
        layer.masksToBounds = true
        layer.cornerRadius = CGFloat(radius)
        layer.borderColor = myColor.cgColor
        layer.borderWidth = CGFloat(borderWidth)
        
        UIGraphicsBeginImageContext(imageView.bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return roundedImage!
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation() // 背景執行時關閉定位功能
    }
    
    func observeUsers(id: String){
        
        FIRDatabase.database().reference().child("mapuser").child(id).observe(FIRDataEventType.value){
            (snapshot: FIRDataSnapshot) in
            if let dict = snapshot.value as? [String:String]
            {
                //取出成員資料
                print(dict)
                let myid = self.senderId
                print("my id=\(myid)")

            }
        }
    }
    
    func observeLocation(){
        
        FIRDatabase.database().reference().child("mapuser").observe(FIRDataEventType.childAdded){
            (snapshot: FIRDataSnapshot) in
            if let dict = snapshot.value as? [String: AnyObject]{
                print("my dict\(dict)")
                let latitude = dict["latitude"] as! String
                let longitude = dict["longitude"] as! String
                print("mapuser latitude\(Double(latitude)!)")
                print("mapuser latitude\(Double(longitude)!)")
                
                // get user profile picture
                var newImage = UIImage()
                if((dict["fileUrl"]) != nil){
                    let fileUrl = dict["fileUrl"] as! String
                    let url = NSURL(string: fileUrl) //把url轉成NSURL
                    let data = NSData(contentsOf: url as! URL)
                    newImage = UIImage(data: data as! Data)!
                }else{
                    newImage = UIImage(named:"default-user-image.png")!
                }
                // make user as marker
                newImage = self.ResizeImage(image: newImage, targetSize: CGSize(width: 80, height:80))
                newImage = self.cropToBounds(image: newImage, width: 100, height: 100)
                let r = (newImage.size.width)/2
                newImage = self.maskRoundedImage(image: newImage, radius: Float(r), borderWidth: 4)
                let marker = GMSMarker()
                marker.icon = newImage
                marker.position = CLLocationCoordinate2DMake(Double(latitude)!, Double(longitude)!
                )
                marker.map = self.mapView
                
                let camera = GMSCameraPosition.camera(withLatitude: Double(latitude)!, longitude: Double(longitude)!, zoom: 10)
                self.mapView.animate(to: camera)
                
                
            }
        }
    }

}

