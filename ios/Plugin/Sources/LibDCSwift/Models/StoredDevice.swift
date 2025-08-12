import Foundation
import CoreBluetooth

extension Notification.Name {
    public static let deviceForgotten = Notification.Name("com.libdc.deviceForgotten")
}

public class StoredDevice: Codable {
   public let uuid: String
   public let name: String
   public let family: DeviceConfiguration.DeviceFamily
   public let model: UInt32
   public let lastConnected: Date
   
   public init(uuid: String, name: String, family: DeviceConfiguration.DeviceFamily, model: UInt32) {
       self.uuid = uuid
       self.name = name
       self.family = family
       self.model = model
       self.lastConnected = Date()
   }
   
   private enum CodingKeys: String, CodingKey {
       case uuid
       case name
       case family
       case model
       case lastConnected
   }
   
   public required init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       uuid = try container.decode(String.self, forKey: .uuid)
       name = try container.decode(String.self, forKey: .name)
       family = try container.decode(DeviceConfiguration.DeviceFamily.self, forKey: .family)
       model = try container.decode(UInt32.self, forKey: .model)
       lastConnected = try container.decode(Date.self, forKey: .lastConnected)
   }
   
   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       try container.encode(uuid, forKey: .uuid)
       try container.encode(name, forKey: .name)
       try container.encode(family, forKey: .family)
       try container.encode(model, forKey: .model)
       try container.encode(lastConnected, forKey: .lastConnected)
   }
}

@objc public class DeviceStorage: NSObject {
   public static let shared = DeviceStorage()
   
   private let defaults = UserDefaults.standard
   private let storageKey = "com.libdc.storedDevices"
   
   private var storedDevices: [StoredDevice] = []
   
   private override init() {
       super.init()
       loadDevices()
   }
   
   private func loadDevices() {
       if let data = defaults.data(forKey: storageKey) {
           do {
               let devices = try JSONDecoder().decode([StoredDevice].self, from: data)
               storedDevices = devices
               logDebug("Loaded \(devices.count) devices from UserDefaults")
           } catch {
               logError("Failed to decode stored devices: \(error)")
           }
       } else {
           logDebug("No stored devices data found in UserDefaults")
       }
   }
   
   private func saveDevices() {
       do {
           let data = try JSONEncoder().encode(storedDevices)
           defaults.set(data, forKey: storageKey)
           defaults.synchronize() // Force immediate save
           logDebug("Saved \(storedDevices.count) devices to UserDefaults")
       } catch {
           logError("Failed to save devices: \(error)")
       }
   }
   
   public func storeDevice(uuid: String, name: String, family: DeviceConfiguration.DeviceFamily, model: UInt32) {
       let device = StoredDevice(uuid: uuid, name: name, family: family, model: model)
       if let index = storedDevices.firstIndex(where: { $0.uuid == uuid }) {
           storedDevices[index] = device
           logDebug("Updated stored device: \(name)")
       } else {
           storedDevices.append(device)
           logDebug("Added new stored device: \(name)")
       }
       saveDevices()
       
       // Verify storage
       if let stored = getStoredDevice(uuid: uuid) {
           logDebug("Successfully stored device: \(stored.name)")
       } else {
           logError("Failed to store device: \(name)")
       }
   }
   
   public func getStoredDevice(uuid: String) -> StoredDevice? {
       return storedDevices.first { $0.uuid == uuid }
   }
   
   public func removeDevice(uuid: String) {
       storedDevices.removeAll { $0.uuid == uuid }
       saveDevices()
       NotificationCenter.default.post(
           name: .deviceForgotten,
           object: nil,
           userInfo: ["deviceUUID": uuid]
       )
   }
   
   public func getLastConnectedDevice() -> StoredDevice? {
       return storedDevices.max(by: { $0.lastConnected < $1.lastConnected })
   }
   
   public func getAllStoredDevices() -> [StoredDevice]? {
       guard let data = defaults.data(forKey: storageKey) else {
           return nil
       }
       
       do {
           let devices = try JSONDecoder().decode([StoredDevice].self, from: data)
           return devices
       } catch {
           logError("Failed to decode stored devices: \(error)")
           return nil
       }
   }
   
   public func updateStoredDevices(_ devices: [StoredDevice]) {
       storedDevices = devices
       saveDevices()
   }
} 
