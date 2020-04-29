//
//  ViewController.swift
//  bluetooth 2 bis
//
//  Created by Máster Móviles on 27/04/2020.
//  Copyright © 2020 Máster Móviles. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

class ViewController: UIViewController {
    
    // MARK: Gradient stuff
    
    let gradient = CAGradientLayer()
    var gradientSet = [[CGColor]]()
    var currentGradient: Int = 0
    
    let gradientOne = UIColor(red: 48/255, green: 62/255, blue: 103/255, alpha: 1).cgColor
    let gradientTwo = UIColor(red: 244/255, green: 88/255, blue: 53/255, alpha: 1).cgColor
    let gradientThree = UIColor(red: 196/255, green: 70/255, blue: 107/255, alpha: 1).cgColor
    
    // MARK: APP stuff
    
    let manager = CMMotionManager()
    let interval = 0.01
    
    let SERVICE_UUID_XY = CBUUID(string: "0BE27C50-8BD0-40A5-AC61-88DC52CE9C64")
    let SERVICE_UUID_SHOOT = CBUUID(string: "5DA21B79-CA3E-4398-A470-4565E6D02A61")
    let CHARACTERISTIC_UUID_SHOOT = CBUUID(string: "8113F397-0840-4BDB-B9C6-DFD6BE7A7172")
    
    let CHARACTERISTIC_UUID_X = CBUUID(string:"C1B89437-74B3-4DA7-9780-9EDAC73CD146")
    let CHARACTERISTIC_UUID_Y = CBUUID(string:"08D12BDA-CAE0-424B-B9F6-478C13CC400B")
    
    let CHARACTERISTIC_PROPERTIES_XY: CBCharacteristicProperties = .notify
    let CHARACTERISTIC_PERMISSIONS_XY: CBAttributePermissions = .readable
    
    let namePeripherical = "Soy el periférico:"
    
    var selectedPeripheral : CBPeripheral!
    var centralManager: CBCentralManager!
    var peripheralManager = CBPeripheralManager()
    
    var myCharacteristicX : CBMutableCharacteristic?
    var myCharacteristicY : CBMutableCharacteristic?
    
    var x : Double = 0.0
    var y : Double = 0.0
    
    var sendingData = false
    
    var central : [CBCentral] = []
    
    var sentX = false
    var sentY = false
    
    var shoot : CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager()
        centralManager.delegate = self
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = interval
        manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: {(data, error) in
            if self.sendingData {
                self.sentX = false
                self.sentY = false
                guard let data = data else { return }
                self.x = data.gravity.x
                self.y = data.gravity.y
                
                self.sentX = self.peripheralManager.updateValue(String(format: "%.4f", self.x).data(using: .utf8)!, for: self.myCharacteristicX!, onSubscribedCentrals: self.central)
                self.sentY = self.peripheralManager.updateValue(String(format: "%.4f", self.y).data(using: .utf8)!, for: self.myCharacteristicY!, onSubscribedCentrals: self.central)
            }
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
        
    }
    
    // MARK: Handle Tap
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        if selectedPeripheral != nil && selectedPeripheral.state == .connected {
            print("shoot")
            if let _ = self.shoot {
                selectedPeripheral.writeValue("0.0000".data(using: .utf8)!, for: self.shoot!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    // MARK: Gradient stuff
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        gradientSet.append([gradientOne, gradientTwo])
        gradientSet.append([gradientTwo, gradientThree])
        gradientSet.append([gradientThree, gradientOne])
        
        gradient.frame = self.view.bounds
        gradient.colors = gradientSet[currentGradient]
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        self.view.layer.addSublayer(gradient)
        
        animateGradient()
    }
    
    func animateGradient() {
        if currentGradient < gradientSet.count - 1 {
            currentGradient += 1
        } else {
            currentGradient = 0
        }
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.delegate = self
        gradientChangeAnimation.duration = 5.0
        gradientChangeAnimation.toValue = gradientSet[currentGradient]
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return .portrait }
    }

}

extension ViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            gradient.colors = gradientSet[currentGradient]
            animateGradient()
        }
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .poweredOn:
            self.centralManager?.scanForPeripherals(withServices: [SERVICE_UUID_SHOOT], options: nil)
            print ("ON")
        case .poweredOff:
            print ("OFF")
        default:
            print(central.state)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let advertisementName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            
            if advertisementName == namePeripherical{
                centralManager?.stopScan()
                selectedPeripheral = peripheral
                selectedPeripheral.delegate = self
                centralManager?.connect(peripheral)
                print ("Central: paramos de escanear periféricos y conectamos con: " + advertisementName)
                
            }
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        
        selectedPeripheral.discoverServices([SERVICE_UUID_SHOOT])
        print ("Central: hemos conectado con el periférico:" + peripheral.name!)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("fail")
    }
}


extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            print ("Central: hemos encontrado un servicio con UUID: " + service.uuid.uuidString)
            if service.uuid == SERVICE_UUID_SHOOT {
                peripheral.discoverCharacteristics([CHARACTERISTIC_UUID_SHOOT], for: service)
                print ("Central: hemos encontrado el servicio y procedemos a descubrir características")
                
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("Central: Hemos encontrado caracterísitca con UUID: " + characteristic.uuid.uuidString + " del periférico:" + characteristic.service.peripheral.name!)
            if (characteristic.uuid == CHARACTERISTIC_UUID_SHOOT)  {
                self.shoot = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {}
    
}

extension ViewController: CBPeripheralManagerDelegate {
    
    // MARK: Publicitar
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn){
            
            if (peripheralManager.isAdvertising) {
                peripheralManager.stopAdvertising()
            }
            
            //Montamos servicio y característica
            let myService = CBMutableService(type: SERVICE_UUID_XY, primary: true)
            self.myCharacteristicX = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_X, properties: CHARACTERISTIC_PROPERTIES_XY, value: nil, permissions: CHARACTERISTIC_PERMISSIONS_XY)
            self.myCharacteristicY = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_Y, properties: CHARACTERISTIC_PROPERTIES_XY, value: nil, permissions: CHARACTERISTIC_PERMISSIONS_XY)
            myService.characteristics = [myCharacteristicX!, myCharacteristicY!]
            //La añadimos al periférico local
            peripheralManager.add(myService)
            print("Periférico: Inicializamos arbol de servicios y características")
            
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[SERVICE_UUID_XY], CBAdvertisementDataLocalNameKey: namePeripherical])
            
            print("Periférico: Empezamos a publicitarnos con el nombre de: " + namePeripherical)
            
        }
        
    }
    // MARK: Errores
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let myError = error {
            print( "Periférico: Error al publicar un servicio:" + myError.localizedDescription)
        }
    }
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let myError = error {
            print( "Periférico: Error al publicitar un servicio:" + myError.localizedDescription)
        }
    }
    // MARK: Nuestras cosas
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        //self.central.removeAll()
        self.central.append(central)
        self.sendingData = true
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        if !self.sentX {
            self.sentX = self.peripheralManager.updateValue(String(format: "%.4f", self.x).data(using: .utf8)!, for: self.myCharacteristicX!, onSubscribedCentrals: self.central)
        }
        if !self.sentY {
            self.sentY = self.peripheralManager.updateValue(String(format: "%.4f", self.y).data(using: .utf8)!, for: self.myCharacteristicY!, onSubscribedCentrals: self.central)
        }
    }

}
