export interface LibDCPlugin {
  /**
   * Initialize the libdivecomputer library
   * @returns Promise with success status
   */
  initialize(): Promise<{ success: boolean }>;

  /**
   * Scan for BLE dive computers
   * @returns Promise with array of discovered devices
   */
  scanDevices(): Promise<{ devices: DeviceInfo[] }>;

  /**
   * Connect to a specific dive computer
   * @param options Connection options
   * @returns Promise with connection status
   */
  connectDevice(options: ConnectOptions): Promise<{ success: boolean }>;

  /**
   * Download dive logs from connected device
   * @param options Download options
   * @returns Promise with array of dive logs
   */
  downloadDives(options: DownloadOptions): Promise<{ dives: DiveLog[] }>;

  /**
   * Disconnect from the connected device
   * @returns Promise with success status
   */
  disconnectDevice(): Promise<{ success: boolean }>;
}

export interface DeviceInfo {
  /**
   * Device name
   */
  name: string;

  /**
   * Device address (BLE address or other identifier)
   */
  address: string;

  /**
   * Device family (manufacturer/model)
   */
  family?: string;

  /**
   * Signal strength (RSSI) for BLE devices
   */
  rssi?: number;
}

export interface ConnectOptions {
  /**
   * Device address to connect to
   */
  address: string;

  /**
   * Device family (if known)
   */
  family?: string;

  /**
   * Connection timeout in milliseconds
   */
  timeout?: number;
}

export interface DownloadOptions {
  /**
   * Whether to force download all dives or use fingerprint system
   */
  forceAll?: boolean;

  /**
   * Fingerprint to use for incremental download
   */
  fingerprint?: string;
}

export interface DiveLog {
  /**
   * Unique identifier for the dive
   */
  id: string;

  /**
   * Fingerprint for the dive (for incremental downloads)
   */
  fingerprint: string;

  /**
   * Dive date and time
   */
  datetime: string;

  /**
   * Maximum depth in meters
   */
  maxDepth?: number;

  /**
   * Dive duration in seconds
   */
  duration?: number;

  /**
   * Raw dive data
   */
  data: string;

  /**
   * Additional dive information
   */
  [key: string]: any;
}