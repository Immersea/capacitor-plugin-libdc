import Foundation
import Clibdivecomputer
import LibDCBridge

/// Represents a stored device fingerprint with associated metadata
public struct DeviceFingerprint: Codable, Identifiable {
    public let id: UUID
    public let deviceType: String
    public let serial: String
    public let fingerprint: Data
    public let timestamp: Date
    
    public init(deviceType: String, serial: String, fingerprint: Data) {
        self.id = UUID()
        self.deviceType = deviceType
        self.serial = serial
        self.fingerprint = fingerprint
        self.timestamp = Date()
    }
}

/// Manages persistent storage of device fingerprints
public class DeviceFingerprintStorage {
    public static let shared = DeviceFingerprintStorage()
    private let fingerprintKey = "DeviceFingerprints"
    
    private init() {}
    
    /// Normalizes a device type string for consistent comparison
    /// Uses libdivecomputer's descriptor system when possible, falls back to string parsing
    /// - Parameter deviceType: The device type string to normalize
    /// - Returns: Normalized device type string
    private func normalizeDeviceType(_ deviceType: String) -> String {
        // Try to find matching descriptor from libdivecomputer
        var descriptor: OpaquePointer?
        let status = find_descriptor_by_name(&descriptor, deviceType)
        
        // If we found a matching descriptor, use its product name
        if status == DC_STATUS_SUCCESS,
           let desc = descriptor,
           let product = dc_descriptor_get_product(desc) {
            let normalizedName = String(cString: product)
            dc_descriptor_free(desc)
            return normalizedName
        }
        
        // If no match found, fall back to basic string parsing
        let components = deviceType.split(separator: " ")
        if components.count == 1 {
            return String(components[0])
        }
        
        // Remove any serial numbers or identifiers (typically numeric)
        let nonNumericComponents = components.filter { !$0.allSatisfy { $0.isNumber } }
        if let modelName = nonNumericComponents.last {
            return String(modelName)
        }
        return deviceType
    }
    
    /// Loads all stored device fingerprints from persistent storage
    /// - Returns: Array of DeviceFingerprint objects
    public func loadFingerprints() -> [DeviceFingerprint] {
        guard let data = UserDefaults.standard.data(forKey: fingerprintKey),
              let fingerprints = try? JSONDecoder().decode([DeviceFingerprint].self, from: data) else {
            return []
        }
        return fingerprints
    }
    
    /// Saves fingerprints to persistent storage
    /// - Parameter fingerprints: Array of DeviceFingerprint objects to save
    public func saveFingerprints(_ fingerprints: [DeviceFingerprint]) {
        if let data = try? JSONEncoder().encode(fingerprints) {
            UserDefaults.standard.set(data, forKey: fingerprintKey)
        }
    }
    
    /// Gets fingerprint for specific device
    /// - Parameters:
    ///   - deviceType: Type/model of the device
    ///   - serial: Serial number of the device
    /// - Returns: Matching DeviceFingerprint if found
    public func getFingerprint(forDeviceType deviceType: String, serial: String) -> DeviceFingerprint? {
        let fingerprints = loadFingerprints()
        let normalizedType = normalizeDeviceType(deviceType)
        let matches = fingerprints.filter { 
            normalizeDeviceType($0.deviceType) == normalizedType && 
            $0.serial == serial 
        }
        
        let found = matches
            .filter { !$0.fingerprint.isEmpty }
            .sorted { $0.timestamp > $1.timestamp }
            .first
            
        if found != nil {
            logInfo("✅ Found stored fingerprint")
        }
        
        return found
    }
    
    /// Saves new fingerprint for device
    /// - Parameters:
    ///   - fingerprint: Fingerprint data to save
    ///   - deviceType: Type/model of device
    ///   - serial: Serial number of device
    public func saveFingerprint(_ fingerprint: Data, deviceType: String, serial: String) {
        var fingerprints = loadFingerprints()
        let normalizedType = normalizeDeviceType(deviceType)
        
        // Remove existing fingerprints for this device
        fingerprints.removeAll { 
            normalizeDeviceType($0.deviceType) == normalizedType && 
            $0.serial == serial 
        }
        
        let newFingerprint = DeviceFingerprint(
            deviceType: deviceType,
            serial: serial,
            fingerprint: fingerprint
        )
        
        fingerprints.append(newFingerprint)
        saveFingerprints(fingerprints)
        logInfo("✅ Saved fingerprint for \(normalizedType) (\(serial))")
    }
    
    /// Clears fingerprint for specific device
    public func clearFingerprint(forDeviceType deviceType: String, serial: String) {
        var fingerprints = loadFingerprints()
        let normalizedType = normalizeDeviceType(deviceType)
        fingerprints.removeAll { 
            normalizeDeviceType($0.deviceType) == normalizedType && 
            $0.serial == serial 
        }
        saveFingerprints(fingerprints)
        logInfo("🗑️ Cleared fingerprint for \(normalizedType) (\(serial))")
    }
    
    /// Clears all stored fingerprints
    public func clearAllFingerprints() {
        UserDefaults.standard.removeObject(forKey: fingerprintKey)
        logInfo("🗑️ Cleared all fingerprints")
    }
} 