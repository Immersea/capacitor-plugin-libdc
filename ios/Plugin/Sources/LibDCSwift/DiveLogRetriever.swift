import Foundation
import CoreBluetooth
import Clibdivecomputer
import LibDCBridge
#if canImport(UIKit)
import UIKit
#endif

/// A class responsible for retrieving dive logs from connected dive computers.
/// Handles the communication with the device, data parsing, and progress tracking.
public class DiveLogRetriever {
    public class CallbackContext {
        var logCount: Int = 1
        let viewModel: DiveDataViewModel
        var lastFingerprint: Data?
        let deviceName: String
        var deviceSerial: String?
        var hasNewDives: Bool = false
        weak var bluetoothManager: CoreBluetoothManager?
        var devicePtr: UnsafeMutablePointer<device_data_t>?
        var hasDeviceInfo: Bool = false
        var storedFingerprint: Data?
        var isCompleted: Bool = false
        
        init(viewModel: DiveDataViewModel, deviceName: String, storedFingerprint: Data?, bluetoothManager: CoreBluetoothManager) {
            self.viewModel = viewModel
            self.deviceName = deviceName
            self.storedFingerprint = storedFingerprint
            self.bluetoothManager = bluetoothManager
        }
    }

    /// C-compatible callback closure for processing individual dive logs.
    /// This is called by libdivecomputer for each dive found on the device.
    /// - Parameters:
    ///   - data: Raw dive data
    ///   - size: Size of the dive data
    ///   - fingerprint: Unique identifier for the dive
    ///   - fsize: Size of the fingerprint
    ///   - userdata: Context data for the callback
    /// - Returns: 1 if successful, 0 if failed
    private static let diveCallbackClosure: @convention(c) (
        UnsafePointer<UInt8>?,
        UInt32,
        UnsafePointer<UInt8>?,
        UInt32,
        UnsafeMutableRawPointer?
    ) -> Int32 = { data, size, fingerprint, fsize, userdata in
        guard let data = data,
              let userdata = userdata,
              let fingerprint = fingerprint else {
            logError("❌ diveCallback: Required parameters are nil")
            return 0
        }
        
        let context = Unmanaged<CallbackContext>.fromOpaque(userdata).takeUnretainedValue()
        
        // Only check isRetrievingLogs because we're relying on clearRetrievalState
        if context.bluetoothManager?.isRetrievingLogs == false {
            logInfo("🛑 Download cancelled - stopping enumeration")
            return 0  // Stop enumeration
        }
        
        // Get device info if we don't have it yet
        if !context.hasDeviceInfo,
           let devicePtr = context.devicePtr,
           devicePtr.pointee.have_devinfo != 0 {
            let deviceSerial = String(format: "%08x", devicePtr.pointee.devinfo.serial)
            context.deviceSerial = deviceSerial
            context.hasDeviceInfo = true
        }
        
        let fingerprintData = Data(bytes: fingerprint, count: Int(fsize))
        if context.logCount == 1 { // Given that first dive is the newest
            context.lastFingerprint = fingerprintData
            logInfo("📍 New fingerprint from latest dive: \(fingerprintData.hexString)")
        }
        
        // Check fingerprint only if we have one stored
        if let storedFingerprint = context.storedFingerprint {
            if storedFingerprint == fingerprintData {
                logInfo("✨ Found matching fingerprint - stopping enumeration")
                return 0
            }
        }
        
        // Always process dive when no fingerprint or no match found
        if let deviceInfo = DeviceConfiguration.fromName(context.deviceName) {
            do {
                let diveData = try GenericParser.parseDiveData(
                    family: deviceInfo.family,
                    model: deviceInfo.model,
                    diveNumber: context.logCount,
                    diveData: data,
                    dataSize: Int(size)
                )
                
                DispatchQueue.main.async {
                    context.viewModel.appendDives([diveData])
                    context.viewModel.updateProgress(count: context.logCount)
                    logInfo("✅ Parsed dive #\(context.logCount - 1)")
                }
                
                context.hasNewDives = true
                context.logCount += 1
                return 1  
            } catch {
                logError("❌ Failed to parse dive #\(context.logCount): \(error)")
                return 0
            }
        }
        
        return 1
    }
    
    #if os(iOS)
    private static var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    /// C callback for fingerprint lookup
    private static let fingerprintLookup: @convention(c) (
        UnsafeMutableRawPointer?, 
        UnsafePointer<CChar>?, 
        UnsafePointer<CChar>?, 
        UnsafeMutablePointer<Int>?
    ) -> UnsafeMutablePointer<UInt8>? = { context, deviceType, serial, size in
        guard let context = context,
              let deviceType = deviceType,
              let serial = serial,
              let size = size else {
            logError("❌ Fingerprint lookup failed: Missing parameters")
            return nil
        }
        
        let viewModel = Unmanaged<DiveDataViewModel>.fromOpaque(context).takeUnretainedValue()
        let deviceTypeStr = String(cString: deviceType)
        var descriptor: OpaquePointer?
        if find_descriptor_by_name(&descriptor, deviceTypeStr) == DC_STATUS_SUCCESS,
           let desc = descriptor,
           let product = dc_descriptor_get_product(desc) {
            let normalizedDeviceType = String(cString: product)
            dc_descriptor_free(desc)
            if let fingerprint = viewModel.getFingerprint(
                forDeviceType: normalizedDeviceType,
                serial: String(cString: serial)
            ) {
                logInfo("✅ Found stored fingerprint: \(fingerprint.hexString)")
                size.pointee = fingerprint.count
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: fingerprint.count)
                fingerprint.copyBytes(to: buffer, count: fingerprint.count)
                return buffer
            }
        }
        logInfo("❌ No stored fingerprint found for \(deviceTypeStr) (\(String(cString: serial)))")
        return nil
    }
    
    private static var currentContext: CallbackContext?
    
    /// Retrieves dive logs from a connected dive computer.
    /// - Parameters:
    ///   - devicePtr: Pointer to the device data structure
    ///   - device: The CoreBluetooth peripheral representing the dive computer
    ///   - viewModel: View model to update UI and store dive data
    ///   - bluetoothManager: Reference to BLE manager
    ///   - onProgress: Optional callback for progress updates
    ///   - completion: Called when retrieval completes or fails
    public static func retrieveDiveLogs(
        from devicePtr: UnsafeMutablePointer<device_data_t>,
        device: CBPeripheral,
        viewModel: DiveDataViewModel,
        bluetoothManager: CoreBluetoothManager,
        onProgress: ((Int, Int) -> Void)? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        let retrievalQueue = DispatchQueue(label: "com.libdcswift.retrieval", qos: .userInitiated)
        
        retrievalQueue.async {
            // Reset only progress at start of new retrieval
            DispatchQueue.main.async {
                viewModel.resetProgress()
            }
            
            guard let dcDevice = devicePtr.pointee.device else {
                DispatchQueue.main.async {
                    viewModel.setDetailedError("No device connection found", status: DC_STATUS_IO)
                    completion(false)
                }
                return
            }

            // Get device info for fingerprint lookup
            let deviceName = device.name ?? "Unknown Device"
            let deviceSerial: String? = if devicePtr.pointee.have_devinfo != 0 {
                String(format: "%08x", devicePtr.pointee.devinfo.serial)
            } else {
                nil
            }
            
            // Only pass stored fingerprint if we want to use it (toggle is ON)
            let storedFingerprint: Data? = if let serial = deviceSerial {
                viewModel.getFingerprint(
                    forDeviceType: deviceName,
                    serial: serial
                )
            } else {
                nil
            }

            // Clear device fingerprint if toggle is OFF
            if storedFingerprint == nil {
                _ = dc_device_set_fingerprint(dcDevice, nil, 0)
                logInfo("💡 No stored fingerprint - downloading all dives")
            }

            let context = CallbackContext(
                viewModel: viewModel,
                deviceName: deviceName,
                storedFingerprint: storedFingerprint,
                bluetoothManager: bluetoothManager
            )
            context.devicePtr = devicePtr
            context.logCount = 1  
            
            let contextPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(context).toOpaque())
            
            let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                if devicePtr.pointee.have_progress != 0 {
                    onProgress?(
                        Int(devicePtr.pointee.progress.current),
                        Int(devicePtr.pointee.progress.maximum)
                    )
                }
            }
            
            devicePtr.pointee.fingerprint_context = Unmanaged.passUnretained(viewModel).toOpaque()
            devicePtr.pointee.lookup_fingerprint = fingerprintLookup
            
            logInfo("🔄 Starting dive enumeration...")
            let enumStatus = dc_device_foreach(dcDevice, diveCallbackClosure, contextPtr)
            
            progressTimer.invalidate()
            DispatchQueue.main.async {
                if enumStatus != DC_STATUS_SUCCESS {
                    viewModel.setDetailedError("Download incomplete", status: enumStatus)
                    completion(false)
                } else {
                    if context.hasNewDives {
                        if let lastFingerprint = context.lastFingerprint,
                           let deviceSerial = context.deviceSerial {
                            viewModel.saveFingerprint(
                                lastFingerprint,
                                deviceType: context.deviceName,
                                serial: deviceSerial
                            )
                            logInfo("💾 Updated fingerprint in persistent storage")
                            viewModel.updateProgress(.completed)
                            completion(true)
                        }
                    } else if context.storedFingerprint != nil {
                        logInfo("✨ No new dives found since last download")
                        viewModel.updateProgress(.noNewDives)
                        completion(true)
                    } else {
                        viewModel.updateProgress(.completed)
                        completion(true)
                    }
                }
                
                context.isCompleted = true
                Unmanaged<CallbackContext>.fromOpaque(contextPtr).release()
                
                #if os(iOS)
                endBackgroundTask()
                #endif
            }
            
            currentContext = context
        }
    }
    
    #if os(iOS)
    private static func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    #endif
    
    public static func getCurrentContext() -> CallbackContext? {
        return currentContext
    }
}

/// Extension to convert Data to hexadecimal string representation
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
