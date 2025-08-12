import Foundation
import CoreBluetooth
import Clibdivecomputer
import LibDCBridge

@objc public class DeviceConfiguration: NSObject {
    /// Represents the family of dive computers that support BLE communication.
    /// Only includes device families that have BLE-capable models.
    public enum DeviceFamily: String, Codable {
        case suuntoEonSteel
        case shearwaterPetrel
        case hwOstc3
        case uwatecSmart
        case oceanicAtom2
        case pelagicI330R
        case maresIconHD
        case deepsixExcursion
        case deepbluCosmiq
        case oceansS1
        case mcleanExtreme
        case divesoftFreedom
        case cressiGoa
        case diveSystem
        
        /// Converts the Swift enum to libdivecomputer's dc_family_t type
        var asDCFamily: dc_family_t {
            switch self {
            case .suuntoEonSteel: return DC_FAMILY_SUUNTO_EONSTEEL
            case .shearwaterPetrel: return DC_FAMILY_SHEARWATER_PETREL
            case .hwOstc3: return DC_FAMILY_HW_OSTC3
            case .uwatecSmart: return DC_FAMILY_UWATEC_SMART
            case .oceanicAtom2: return DC_FAMILY_OCEANIC_ATOM2
            case .pelagicI330R: return DC_FAMILY_PELAGIC_I330R
            case .maresIconHD: return DC_FAMILY_MARES_ICONHD
            case .deepsixExcursion: return DC_FAMILY_DEEPSIX_EXCURSION
            case .deepbluCosmiq: return DC_FAMILY_DEEPBLU_COSMIQ
            case .oceansS1: return DC_FAMILY_OCEANS_S1
            case .mcleanExtreme: return DC_FAMILY_MCLEAN_EXTREME
            case .divesoftFreedom: return DC_FAMILY_DIVESOFT_FREEDOM
            case .cressiGoa: return DC_FAMILY_CRESSI_GOA
            case .diveSystem: return DC_FAMILY_DIVESYSTEM_IDIVE
            }
        }
        
        /// Creates a DeviceFamily instance from libdivecomputer's dc_family_t type
        /// - Parameter dcFamily: The dc_family_t value to convert
        /// - Returns: The corresponding DeviceFamily case, or nil if not supported
        init?(dcFamily: dc_family_t) {
            switch dcFamily {
            case DC_FAMILY_SUUNTO_EONSTEEL: self = .suuntoEonSteel
            case DC_FAMILY_SHEARWATER_PETREL: self = .shearwaterPetrel
            case DC_FAMILY_HW_OSTC3: self = .hwOstc3
            case DC_FAMILY_UWATEC_SMART: self = .uwatecSmart
            case DC_FAMILY_OCEANIC_ATOM2: self = .oceanicAtom2
            case DC_FAMILY_PELAGIC_I330R: self = .pelagicI330R
            case DC_FAMILY_MARES_ICONHD: self = .maresIconHD
            case DC_FAMILY_DEEPSIX_EXCURSION: self = .deepsixExcursion
            case DC_FAMILY_DEEPBLU_COSMIQ: self = .deepbluCosmiq
            case DC_FAMILY_OCEANS_S1: self = .oceansS1
            case DC_FAMILY_MCLEAN_EXTREME: self = .mcleanExtreme
            case DC_FAMILY_DIVESOFT_FREEDOM: self = .divesoftFreedom
            case DC_FAMILY_CRESSI_GOA: self = .cressiGoa
            case DC_FAMILY_DIVESYSTEM_IDIVE: self = .diveSystem
            default: return nil
            }
        }
    }
    
    /// Known BLE service UUIDs for supported dive computers.
    /// Used for device discovery and identification.
    private static let knownServiceUUIDs: [CBUUID] = [
        CBUUID(string: "0000fefb-0000-1000-8000-00805f9b34fb"), // Heinrichs-Weikamp Telit/Stollmann
        CBUUID(string: "2456e1b9-26e2-8f83-e744-f34f01e9d701"), // Heinrichs-Weikamp U-Blox
        CBUUID(string: "544e326b-5b72-c6b0-1c46-41c1bc448118"), // Mares BlueLink Pro
        CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic Semi UART
        CBUUID(string: "98ae7120-e62e-11e3-badd-0002a5d5c51b"), // Suunto EON Steel/Core
        CBUUID(string: "cb3c4555-d670-4670-bc20-b61dbc851e9a"), // Pelagic i770R/i200C
        CBUUID(string: "ca7b0001-f785-4c38-b599-c7c5fbadb034"), // Pelagic i330R/DSX
        CBUUID(string: "fdcdeaaa-295d-470e-bf15-04217b7aa0a0"), // ScubaPro G2/G3
        CBUUID(string: "fe25c237-0ece-443c-b0aa-e02033e7029d"), // Shearwater Perdix/Teric
        CBUUID(string: "0000fcef-0000-1000-8000-00805f9b34fb")  // Divesoft Freedom
    ]
    
    /// Returns an array of known BLE service UUIDs for supported dive computers.
    /// - Returns: Array of CBUUIDs representing known service UUIDs
    public static func getKnownServiceUUIDs() -> [CBUUID] {
        return knownServiceUUIDs
    }
    
    /// Attempts to open a BLE connection to a dive computer.
    /// This function will try multiple methods to identify and connect to the device:
    /// 1. Use stored device information if available
    /// 2. Use descriptor system to identify device
    /// - Parameters:
    ///   - name: The advertised name of the BLE device
    ///   - deviceAddress: The device's UUID/MAC address
    /// - Returns: True if connection was successful, false otherwise
    @objc public static func openBLEDevice(name: String, deviceAddress: String) -> Bool {
        logDebug("Attempting to open BLE device: \(name) at address: \(deviceAddress)")
        
        var deviceData: UnsafeMutablePointer<device_data_t>?
        let storedDevice = DeviceStorage.shared.getStoredDevice(uuid: deviceAddress)
        
        if let storedDevice = storedDevice {
            logDebug("Found stored device configuration - Family: \(storedDevice.family), Model: \(storedDevice.model)")
        }
        
        let status = open_ble_device_with_identification(
            &deviceData,
            name,
            deviceAddress,
            storedDevice?.family.asDCFamily ?? DC_FAMILY_NULL,
            storedDevice?.model ?? 0
        )
        
        if status == DC_STATUS_SUCCESS, let data = deviceData {
            logDebug("Successfully opened device")
            logDebug("Device data pointer allocated at: \(String(describing: data))")
            DispatchQueue.main.async {
                if let manager = CoreBluetoothManager.shared() as? CoreBluetoothManager {
                    manager.openedDeviceDataPtr = data
                }
            }
            return true
        }
        
        logError("Failed to open device (status: \(status))")
        if let data = deviceData {
            data.deallocate()
        }
        return false
    }
    
    /// Identifies a BLE device from its name using libdivecomputer's descriptor system
    /// - Parameter name: The device name to identify
    /// - Returns: A tuple containing the device family and model number, or nil if not identified
    public static func fromName(_ name: String) -> (family: DeviceFamily, model: UInt32)? {
        var descriptor: OpaquePointer?
        
        let rc = find_descriptor_by_name(&descriptor, name)
        if rc == DC_STATUS_SUCCESS,
           let desc = descriptor {
            let family = dc_descriptor_get_type(desc)
            let model = dc_descriptor_get_model(desc)
            if let deviceFamily = DeviceFamily(dcFamily: family) {
                dc_descriptor_free(desc)
                return (deviceFamily, model)
            }
            dc_descriptor_free(desc)
        }
        return nil
    }
    
    /// Returns a human-readable display name for a device using libdivecomputer's vendor and product information.
    /// Only considers BLE-capable devices.
    /// - Parameter name: The device name to get display name for
    /// - Returns: A formatted string containing the vendor and product name, or the original name if not found
    public static func getDeviceDisplayName(from name: String) -> String {
        if let cString = get_formatted_device_name(name) {
            defer { free(cString) }
            return String(cString: cString)
        }
        return name
    }
    
    private var descriptor: OpaquePointer?
    private static var context: OpaquePointer?
    
    /// Setup the shared device context
    public static func setupContext() {
        if context == nil {
            let rc = dc_context_new(&context)
            if rc != DC_STATUS_SUCCESS {
                logError("Failed to create dive computer context")
            }
        }
    }
    
    /// Cleanup the shared device context
    public static func cleanupContext() {
        if let ctx = context {
            dc_context_free(ctx)
            context = nil
        }
    }
    
    /// Creates a parser for dive data
    /// - Parameters:
    ///   - family: Device family
    ///   - model: Device model
    ///   - data: Raw dive data to parse
    /// - Returns: Parser instance if successful, nil otherwise
    public static func createParser(family: dc_family_t, model: UInt32, data: Data) -> OpaquePointer? {
        guard let context = context else {
            logError("No dive computer context available")
            return nil
        }
        
        var parser: OpaquePointer?
        let rc = create_parser_for_device(
            &parser,
            context,
            family,
            model,
            [UInt8](data),
            data.count
        )
        if rc != DC_STATUS_SUCCESS {
            logError("Failed to create parser: \(rc)")
            return nil
        }
        return parser
    }
}
