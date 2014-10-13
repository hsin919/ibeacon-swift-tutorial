//
//  AppDelegate.swift
//  iBeaconTemplateSwift
//
//  Created by James Nick Sears on 7/1/14.
//  Copyright (c) 2014 iBeaconModules.us. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
CBCentralManagerDelegate, CBPeripheralDelegate{
                            
    var window: UIWindow?
    var locationManager: CLLocationManager?
    var centralManager: CBCentralManager?
    var _peripheral: CBPeripheral?
    var lastProximity: CLProximity?

    let kServiceUUID = "E28E86A2-45A2-4E39-B0F0-045446794698"
    let kCharacteristicUUID = "4FBAF52F-925F-4958-86EF-68984BEFB5C7"
    
    func application(application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        let uuidString = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
        let beaconIdentifier = "com.beaconDemo"
            
        
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID,
            identifier: beaconIdentifier)
            
        locationManager = CLLocationManager()

        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
            
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
        locationManager!.startUpdatingLocation()
            
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound,
                    categories: nil
                )
            )
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
            
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
        case CBCentralManagerState.Unauthorized:
            println("CBCentralManagerState.Unauthorized")
        case CBCentralManagerState.PoweredOn:
            println("CBCentralManagerState.PoweredOn")
            centralManager?.scanForPeripheralsWithServices(nil, options: nil)
        default:
            println("\(central.state.toRaw())")
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        NSLog("%s", __FUNCTION__)
        println("Discover \(peripheral.name) rssi\(RSSI)")
        
        centralManager?.stopScan()
        _peripheral = peripheral
        
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("%s", __FUNCTION__)
        println("Connected with \(peripheral.name)")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("%s", __FUNCTION__)
        println("Connected with \(peripheral.name)")
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("%s", __FUNCTION__)
        println("Connected with \(peripheral.name)")
    }
}

extension AppDelegate: CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        NSLog("%s", __FUNCTION__)
        if((error) != nil) {
            NSLog("!!!error :%@", error.localizedDescription)
            return;
        }
        for  service in peripheral.services {
            println("Discover service \(service)")
            println("UUID \(service.UUID)")
            if(service.UUID == CBUUID.UUIDWithString(kServiceUUID)){
                let Service = (service as CBService)
                peripheral.discoverCharacteristics(nil , forService: Service)
                
                sendLocalNotificationWithMessage("Welcome to iPhone6 plus station", playSound: false)
            }
        }
    }
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!)
    {
        NSLog("%s", __FUNCTION__)
        if((error) != nil) {
            NSLog("!!!error :%@", error.localizedDescription)
            return;
        }
        for  service in peripheral.services {
            println("Discover service \(service)")
            println("UUID \(service.UUID)")
            if(service.UUID == CBUUID.UUIDWithString(kServiceUUID)){
                let Service = (service as CBService)
                peripheral.discoverCharacteristics(nil , forService: Service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!)
    {
        if((error) != nil) {
            NSLog("!!!error :%@", error.localizedDescription)
            return;
        }
        for characteristic in service.characteristics{
            if(characteristic.UUID == CBUUID.UUIDWithString(kCharacteristicUUID)){
                println("Discover characteristic \(characteristic)")
                _peripheral?.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if((error) != nil) {
            NSLog("!!!error :%@", error.localizedDescription)
            return;
        }
        
        let receiveStr = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
        NSLog("%@", receiveStr)
        sendLocalNotificationWithMessage("\(receiveStr)", playSound: false)
        
    }
}

extension AppDelegate: CLLocationManagerDelegate {
	func sendLocalNotificationWithMessage(message: String!, playSound: Bool) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
		
		if(playSound) {
			// classic star trek communicator beep
			//	http://www.trekcore.com/audio/
			//
			// note: convert mp3 and wav formats into caf using:
			//	"afconvert -f caff -d LEI16@44100 -c 1 in.wav out.caf"
			// http://stackoverflow.com/a/10388263

			notification.soundName = "tos_beep.caf";
		}
		
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
            let viewController:ViewController = window!.rootViewController as ViewController
            viewController.beacons = beacons as [CLBeacon]?
            viewController.tableView!.reloadData()
            
            //NSLog("didRangeBeacons");
            var message:String = ""
			
			var playSound = false
            
            if(beacons.count > 0) {
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                
                if(nearestBeacon.proximity == lastProximity ||
                    nearestBeacon.proximity == CLProximity.Unknown) {
                        return;
                }
                lastProximity = nearestBeacon.proximity;
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    message = "You are far away from the beacon"
					playSound = true
                case CLProximity.Near:
                    message = "You are near the beacon"
                    centralManager?.cancelPeripheralConnection(_peripheral)
                case CLProximity.Immediate:
                    message = "You are in the immediate proximity of the beacon"
                    centralManager?.connectPeripheral(_peripheral, options: nil)
                case CLProximity.Unknown:
                    return
                }
            } else {
				
				if(lastProximity == CLProximity.Unknown) {
					return;
				}
				
                message = "No beacons are nearby"
				playSound = true
				lastProximity = CLProximity.Unknown
            }
			
            NSLog("%@", message)
			sendLocalNotificationWithMessage(message, playSound: playSound)
    }
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.startUpdatingLocation()
            
            NSLog("You entered the region")
            sendLocalNotificationWithMessage("You entered the region", playSound: false)
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.stopUpdatingLocation()
            
            NSLog("You exited the region")
            sendLocalNotificationWithMessage("You exited the region", playSound: true)
    }
}

