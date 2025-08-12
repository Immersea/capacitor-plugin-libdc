import Foundation
import Capacitor
import CoreBluetooth

/**
 * Capacitor plugin for libdivecomputer integration
 */
@objc(LibDCPlugin)
public class LibDCPlugin: CAPPlugin {
    private var implementation: LibDCImplementation?
    
    override public func load() {
        implementation = LibDCImplementation()
    }
    
    @objc func initialize(_ call: CAPPluginCall) {
        guard let implementation = implementation else {
            call.reject("Plugin not initialized")
            return
        }
        
        implementation.initialize { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to initialize")
            }
        }
    }
    
    @objc func scanDevices(_ call: CAPPluginCall) {
        guard let implementation = implementation else {
            call.reject("Plugin not initialized")
            return
        }
        
        implementation.scanDevices { devices, error in
            if let devices = devices {
                let deviceMaps = devices.map { device -> [String: Any] in
                    var deviceMap: [String: Any] = [
                        "name": device.name ?? "",
                        "address": device.address
                    ]
                    
                    if let family = device.family {
                        deviceMap["family"] = family
                    }
                    
                    if let rssi = device.rssi {
                        deviceMap["rssi"] = rssi
                    }
                    
                    return deviceMap
                }
                
                call.resolve(["devices": deviceMaps])
            } else {
                call.reject(error ?? "Failed to scan devices")
            }
        }
    }
    
    @objc func connectDevice(_ call: CAPPluginCall) {
        guard let implementation = implementation else {
            call.reject("Plugin not initialized")
            return
        }
        
        guard let address = call.getString("address") else {
            call.reject("Device address is required")
            return
        }
        
        let family = call.getString("family")
        let timeout = call.getInt("timeout")
        
        implementation.connectDevice(address: address, family: family, timeout: timeout) { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to connect to device")
            }
        }
    }
    
    @objc func downloadDives(_ call: CAPPluginCall) {
        guard let implementation = implementation else {
            call.reject("Plugin not initialized")
            return
        }
        
        let forceAll = call.getBool("forceAll") ?? false
        let fingerprint = call.getString("fingerprint")
        
        implementation.downloadDives(forceAll: forceAll, fingerprint: fingerprint) { dives, error in
            if let dives = dives {
                let diveMaps = dives.map { dive -> [String: Any] in
                    var diveMap: [String: Any] = [
                        "id": dive.id,
                        "fingerprint": dive.fingerprint,
                        "datetime": dive.datetime,
                        "data": dive.data
                    ]
                    
                    if let maxDepth = dive.maxDepth {
                        diveMap["maxDepth"] = maxDepth
                    }
                    
                    if let duration = dive.duration {
                        diveMap["duration"] = duration
                    }
                    
                    // Add any additional properties
                    for (key, value) in dive.additionalInfo {
                        diveMap[key] = value
                    }
                    
                    return diveMap
                }
                
                call.resolve(["dives": diveMaps])
            } else {
                call.reject(error ?? "Failed to download dives")
            }
        }
    }
    
    @objc func disconnectDevice(_ call: CAPPluginCall) {
        guard let implementation = implementation else {
            call.reject("Plugin not initialized")
            return
        }
        
        implementation.disconnectDevice { success, error in
            if success {
                call.resolve(["success": true])
            } else {
                call.reject(error ?? "Failed to disconnect device")
            }
        }
    }
}