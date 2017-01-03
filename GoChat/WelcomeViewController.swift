//
//  WelcomeViewController.swift
//  GoChat
//
//  Created by 鄭薇 on 2017/1/3.
//  Copyright © 2017年 LilyCheng. All rights reserved.
//

import UIKit
import Foundation

class WelcomeViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func UserInfoButton(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let UserInfoVC = storyBoard.instantiateViewController(withIdentifier: "LoginVC")
        self.present(UserInfoVC, animated:true, completion:nil)
    }
}
