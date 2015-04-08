//
//  ViewController.swift
//  FakeAgent
//
//  Created by Jay Tucker on 4/8/15.
//  Copyright (c) 2015 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func enroll(sender: AnyObject) {
        println("enroll")
    }
    
    @IBAction func auth(sender: AnyObject) {
        println("auth")
    }
    
}

