//
//  RoomsViewController.swift
//  GoChat
//
//  Created by 鄭薇 on 2016/12/19.
//  Copyright © 2016年 LilyCheng. All rights reserved.
//
import Foundation
import UIKit
import Firebase
import FirebaseDatabase

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelsSection
}


class RoomsViewController: UIViewController {
    
    // MARK: Properties
    var senderDisplayName: String?
    var newRoomTextField: UITextField?
    let uuid: String =  UIDevice.current.identifierForVendor!.uuidString
    
    private var roomRefHandle: FIRDatabaseHandle?
    private var rooms: [Room] = []  //本意是在tableview上列出所有已存在房間
    
    private lazy var roomRef: FIRDatabaseReference = FIRDatabase.database().reference().child("TripGifRooms")
    
    // MARK: TextField
    @IBOutlet weak var InputRoomName: UITextField!
    @IBOutlet weak var InputRoomNum: UITextField!
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "嗨！ " + senderDisplayName!   //將最上面標題設為嗨！使用者暱稱
        observeRoom()
    }
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
    
    // MARK :Actions
    //登出
    func observeRoom(){
        FIRDatabase.database().reference().child("TripGifUsers").child(uuid).child("myRooms").observe(.value, with:{
            snapshot in
            print("目前有的房間")
            for child in snapshot.children{
                let existRoom = (child as AnyObject).key as String
                print(existRoom)
            }
        })
        
    }
    
    @IBAction func Logout(_ sender: Any) {
        print("User logged out")
        do{
            try FIRAuth.auth()?.signOut()
        }catch let error{
            print(error)
        }
        print(FIRAuth.auth()?.currentUser)
        //Create a main storyboard instance
        let storyboard = UIStoryboard(name : "Main", bundle: nil)
        
        //From main storyboard instantiate a View controller
        let LoginVC = storyboard.instantiateViewController(withIdentifier:"LoginVC")as!LoginViewController
        //Get the app delegate
        let appDelegate = UIApplication.shared.delegate as!AppDelegate
        //Set Login Conteoller as root view controller
        appDelegate.window?.rootViewController = LoginVC
    }
    //創新房間到房間資料庫中
    @IBAction func NewRoom(_ sender: Any) {
        if InputRoomName?.text != ""{                                   //房間名的input field不可為空
            let roomName = self.InputRoomName.text                      //接到的房間名
            let randomRoomNum:UInt32 = arc4random_uniform(9999)       //亂數產生四位數房號
//            var randomRoomNum:UInt32 = 8212
//            var canCreate:Bool = false
//            while(canCreate == false){
//                if(validRoomNum(roomNum: randomRoomNum) == false){       //如果檢查在資料庫不重複==false
//                    randomRoomNum = arc4random_uniform(9999)             //蓋掉舊的創一個新的四位數房號
//                }else{
//                    canCreate = true
//                }
//            }
            
            let newRoomRef = roomRef.child(String(randomRoomNum))       //定義firebase裡的reference
            
            let roomItem = ["RoomName":roomName!, "RoomNum": String(describing: randomRoomNum)]
            newRoomRef.setValue(roomItem)
            print("房間ref: " + String(describing: newRoomRef))
            print("房間name: " + roomName!)
            print("房間num: " + String(describing: randomRoomNum))
            
            //創建成功小視窗
            let alert = UIAlertController(title: "成功創立房間！", message: "名稱:" + roomName! + "\n房號:" + String(describing: randomRoomNum), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            //創建失敗小視窗
            let alert = UIAlertController(title: "請務必輸入房名", message: "您輸入的名字會作為新開聊天室名稱", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
    
    @IBAction func EnterRoom(_ sender: Any) {
        if InputRoomNum?.text != ""{                               //房號不可為空
            let countChar = InputRoomNum.text?.characters.count
            if countChar != 4{
                //房號四位數不對 失敗小視窗
                let alert = UIAlertController(title: "房號只能為四位數", message: "請重新輸入！", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            // 刷新user裡的room資料
            let roomNumber = (self.InputRoomNum.text)!
//            FIRDatabase.database().reference().child("TripGifUsers").child(uuid).child("myRooms").childByAutoId().setValue(roomNumber)
            FIRDatabase.database().reference().child("TripGifUsers").child(uuid).child("myRooms").child(roomNumber).setValue(true)
            
            roomRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.value is NSNull{
                    print("不存在任何房間")
                }else{
                    for child in snapshot.children{
                        let existRoom = (child as AnyObject).key as String
                        print("現有房間 " + existRoom)
                    }
                    //let wantedRoomSender = self.rooms 我把sender弄成self就可以了，原本是 wantedRoomSender
                    print("輸入了想進的房號是 " + self.InputRoomNum.text!)
                }
            })
        }else{
        //房號空白 失敗小視窗
            let alert = UIAlertController(title: "請務必輸入房號", message: "沒輸房號怎麼進房呢？", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
    
    // MARK: Firebase related methods
    
    // firebase中房號沒重複這個function便會回傳true
    private func validRoomNum(roomNum: UInt32) -> Bool{
        let testRoomNum = String(describing: roomNum)
        var testValid = false
        FIRDatabase.database().reference().child("TripGifRooms").observe(.value, with:{
            snapshot in
            if let observeRoom = snapshot.value as? [String:AnyObject]
            {
                print(observeRoom)
                let check = (observeRoom["RoomNum"]as! String)
                if(testRoomNum == check){
                    testValid = false
                }else{
                    testValid = true
                }
            }
        })
        return testValid
    }
    
    // MARK: Navigation
    override func prepare(for segue:UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "ShowMapChat"{
            let chatVc = segue.destination as! RoomMapViewController
            let targetNum = self.InputRoomNum.text! as String
            chatVc.senderDisplayName = senderDisplayName!
            chatVc.targetRoomNum = targetNum
            print("傳segue進聊天地圖中...")
        }
        else{print("傳值error!!!!!!!!!!!")}
    }    
}
