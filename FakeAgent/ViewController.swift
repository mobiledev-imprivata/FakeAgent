//
//  ViewController.swift
//  FakeAgent
//
//  Created by Jay Tucker on 4/8/15.
//  Copyright (c) 2015 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var bluetoothManager: BluetoothManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        bluetoothManager = BluetoothManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func enroll(sender: AnyObject) {
        bluetoothManager.enroll()
    }
    
    @IBAction func auth(sender: AnyObject) {
        bluetoothManager.auth()
    }
    
}

