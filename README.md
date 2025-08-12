# Capacitor Plugin LibDC

A Capacitor plugin for integrating libdivecomputer functionality into mobile applications, enabling communication with dive computers and downloading dive logs.

## Features

- 🔍 **Device Scanning**: Discover nearby dive computers via Bluetooth
- 🔗 **Device Connection**: Connect to specific dive computers
- 📥 **Dive Log Download**: Retrieve dive logs with incremental download support
- 📱 **Cross-Platform**: Works on both iOS and Android
- 🔒 **Permission Handling**: Automatic Bluetooth and location permission management

## Installation

```bash
npm install capacitor-plugin-libdc
npx cap sync
```

## Platform Setup

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to dive computers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to dive computers</string>
```

### Android

The plugin automatically handles the required permissions:
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `ACCESS_FINE_LOCATION`
- `BLUETOOTH_SCAN` (Android 12+)
- `BLUETOOTH_CONNECT` (Android 12+)

## Usage

```typescript
import { LibDC } from 'capacitor-plugin-libdc';

// Initialize the plugin
const initResult = await LibDC.initialize();
if (initResult.success) {
  console.log('LibDC initialized successfully');
}

// Scan for devices
const scanResult = await LibDC.scanDevices();
console.log('Found devices:', scanResult.devices);

// Connect to a device
const connectResult = await LibDC.connectDevice({
  address: 'device-address',
  family: 'suuntoEonSteel', // optional
  timeout: 10000 // optional, in milliseconds
});

if (connectResult.success) {
  // Download dives
  const downloadResult = await LibDC.downloadDives({
    forceAll: false, // use fingerprint for incremental download
    fingerprint: 'previous-fingerprint' // optional
  });
  
  console.log('Downloaded dives:', downloadResult.dives);
  
  // Disconnect when done
  await LibDC.disconnectDevice();
}
```

## API Reference

### `initialize()`

Initializes the libdivecomputer library and checks Bluetooth availability.

**Returns:** `Promise<{ success: boolean }>`

### `scanDevices()`

Scans for nearby dive computers via Bluetooth.

**Returns:** `Promise<{ devices: DeviceInfo[] }>`

### `connectDevice(options: ConnectOptions)`

Connects to a specific dive computer.

**Parameters:**
- `address: string` - Device address
- `family?: string` - Device family (optional)
- `timeout?: number` - Connection timeout in milliseconds (optional)

**Returns:** `Promise<{ success: boolean }>`

### `downloadDives(options: DownloadOptions)`

Downloads dive logs from the connected device.

**Parameters:**
- `forceAll?: boolean` - Force download all dives (default: false)
- `fingerprint?: string` - Fingerprint for incremental download (optional)

**Returns:** `Promise<{ dives: DiveLog[] }>`

### `disconnectDevice()`

Disconnects from the currently connected device.

**Returns:** `Promise<{ success: boolean }>`

## Data Types

### `DeviceInfo`

```typescript
interface DeviceInfo {
  name: string;        // Device name
  address: string;     // Device address
  family?: string;     // Device family
  rssi?: number;       // Signal strength (BLE only)
}
```

### `DiveLog`

```typescript
interface DiveLog {
  id: string;          // Unique identifier
  fingerprint: string; // Fingerprint for incremental downloads
  datetime: string;    // Dive date and time (ISO 8601)
  maxDepth?: number;   // Maximum depth in meters
  duration?: number;   // Dive duration in seconds
  data: string;        // Raw dive data (Base64 encoded)
  [key: string]: any;  // Additional dive information
}
```

## Supported Dive Computer Families

- Suunto (suuntoEonSteel)
- Shearwater (shearwaterPetrel)
- OSTC (hwOstc3)
- And more...

## Development

### Building

```bash
npm run build
```

### Native Library Integration

The plugin integrates with:
- **iOS**: libdc-swift library
- **Android**: libdivecomputer-java library

Use the provided copy scripts to update native libraries:

```bash
# iOS
cd ios && ./copy_libdc_files.sh

# Android
cd android && ./copy_libdc_files.sh
```

## License

MIT

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.