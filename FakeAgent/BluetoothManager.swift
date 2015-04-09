//
//  BluetoothManager.swift
//  FakeAgent
//
//  Created by Jay Tucker on 4/8/15.
//  Copyright (c) 2015 Imprivata. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject {
    
    enum State: Printable {
        case Enroll1
        case Enroll2
        case Enroll3
        case Auth
        
        var description: String {
            switch self {
            case .Enroll1: return "Enroll1"
            case .Enroll2: return "Enroll2"
            case .Enroll3: return "Enroll3"
            case .Auth: return "Auth"
            }
        }
    }
    
    private let enrollServiceUUID              = CBUUID(string: "80CBFCD9-C13A-4817-8921-349F3702A4D0")
    private let enrollInputCharacteristicUUID  = CBUUID(string: "40A70AAD-6E05-4EBD-B9DB-2010DC412881")
    private let enrollOutputCharacteristicUUID = CBUUID(string: "AC103510-5E49-41C5-94DA-CBA4329A6CF5")
    
    private var authServiceUUID                = CBUUID(string: "1012A197-B767-421C-B49C-10F385BA22E1")
    private let authInputCharacteristicUUID    = CBUUID(string: "E11C666D-A68C-4775-A05E-2765830D5D60")
    private let authOutputCharacteristicUUID   = CBUUID(string: "BEDFA15A-9048-4ABD-8455-6E164F4878E3")
    
    private var currentServiceUUID: CBUUID!
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    var responseCharacteristic: CBCharacteristic!
    
    private var isPoweredOn = false
    private var scanTimer: NSTimer!
    private let timeoutInSecs = 5.0
    
    private var isBusy = false
    
    private var pendingRequest: String!
    
    private var state: State!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    private func nameFromUUID(uuid: CBUUID) -> String {
        switch uuid {
        case enrollServiceUUID: return "enrollService"
        case enrollInputCharacteristicUUID: return "enrollInput"
        case enrollOutputCharacteristicUUID: return "enrollOutput"
        case authServiceUUID: return "authService"
        case authInputCharacteristicUUID: return "authInput"
        case authOutputCharacteristicUUID: return "authOutput"
        default: return "unknown"
        }
    }
    
    func enroll() {
        log("enroll")
        if isBusy {
            log("busy, ignoring")
            return
        }
        if !isPoweredOn {
            log("not powered on")
            return
        }
        isBusy = true
        currentServiceUUID = enrollServiceUUID
        startScanForPeripheralWithService(enrollServiceUUID)
    }
    
    func auth() {
        log("auth")
        if isBusy {
            log("busy, ignoring")
            return
        }
        if !isPoweredOn {
            log("not powered on")
            return
        }
        isBusy = true
        currentServiceUUID = authServiceUUID
        startScanForPeripheralWithService(authServiceUUID)
    }
    
    private func sendRequest(request: String) {
        log("sendCommand")
        startScanForPeripheralWithService(currentServiceUUID)
    }
    
    private func processResponse(responseData: NSData) {
        
    }
    
    private func startScanForPeripheralWithService(uuid: CBUUID) {
        log("startScanForPeripheralWithService \(nameFromUUID(uuid)) \(uuid)")
        centralManager.stopScan()
        scanTimer = NSTimer.scheduledTimerWithTimeInterval(timeoutInSecs, target: self, selector: Selector("timeout"), userInfo: nil, repeats: false)
        centralManager.scanForPeripheralsWithServices([uuid], options: nil)
    }
    
    // can't be private because called by timer
    func timeout() {
        log("timed out")
        centralManager.stopScan()
        isBusy = false
    }
    
    private func disconnect() {
        log("disconnect")
        centralManager.cancelPeripheralConnection(peripheral)
        self.peripheral = nil
        self.responseCharacteristic = nil
        isBusy = false
    }
    
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        var caseString: String!
        switch centralManager.state {
        case .Unknown:
            caseString = "Unknown"
        case .Resetting:
            caseString = "Resetting"
        case .Unsupported:
            caseString = "Unsupported"
        case .Unauthorized:
            caseString = "Unauthorized"
        case .PoweredOff:
            caseString = "PoweredOff"
        case .PoweredOn:
            caseString = "PoweredOn"
        default:
            caseString = "WTF"
        }
        log("centralManagerDidUpdateState \(caseString)")
        isPoweredOn = (centralManager.state == .PoweredOn)
        if isPoweredOn {
            enroll()
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        log("centralManager didDiscoverPeripheral")
        scanTimer.invalidate()
        centralManager.stopScan()
        self.peripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        log("centralManager didConnectPeripheral")
        self.peripheral.delegate = self
        peripheral.discoverServices([currentServiceUUID])
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            log("peripheral didDiscoverServices ok")
        } else {
            log("peripheral didDiscoverServices error \(error.localizedDescription)")
            return
        }
        if peripheral.services.isEmpty {
            log("no services found")
            disconnect()
            return
        }
        for service in peripheral.services {
            log("service \(nameFromUUID(service.UUID))  \(service.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service as! CBService)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error == nil {
            log("peripheral didDiscoverCharacteristicsForService \(nameFromUUID(service.UUID)) \(service.UUID) ok")
        } else {
            log("peripheral didDiscoverCharacteristicsForService \(nameFromUUID(service.UUID)) \(service.UUID) error \(error.localizedDescription)")
            return
        }
        for characteristic in service.characteristics {
            let name = nameFromUUID(characteristic.UUID)
            log("characteristic \(name) \(characteristic.UUID)")
//            if characteristic.UUID == enrollInputCharacteristicUUID {
//                let data = "Hello, World!".dataUsingEncoding(NSUTF8StringEncoding)
//                peripheral.writeValue(data, forCharacteristic: characteristic as! CBCharacteristic, type: CBCharacteristicWriteType.WithResponse)
//            } else if characteristic.UUID == responseCharacteristicUUID {
//                responseCharacteristic = characteristic as CBCharacteristic
//            }
        }
        disconnect()
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            log("peripheral didWriteValueForCharacteristic ok")
            peripheral.readValueForCharacteristic(responseCharacteristic)
        } else {
            log("peripheral didWriteValueForCharacteristic error \(error.localizedDescription)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            let name = nameFromUUID(characteristic.UUID)
            log("peripheral didUpdateValueForCharacteristic \(name) ok")
            let value: String = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)! as String
            log("received response: \(value)")
        } else {
            log("peripheral didUpdateValueForCharacteristic error \(error.localizedDescription)")
            return
        }
    }
    
}