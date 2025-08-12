import { WebPlugin } from '@capacitor/core';

import type { ConnectOptions, DeviceInfo, DownloadOptions, DiveLog, LibDCPlugin } from './definitions';

export class LibDCWeb extends WebPlugin implements LibDCPlugin {
  async initialize(): Promise<{ success: boolean }> {
    console.warn('LibDC.initialize(): This method is not implemented on web');
    return { success: false };
  }

  async scanDevices(): Promise<{ devices: DeviceInfo[] }> {
    console.warn('LibDC.scanDevices(): This method is not implemented on web');
    return { devices: [] };
  }

  async connectDevice(options: ConnectOptions): Promise<{ success: boolean }> {
    console.warn('LibDC.connectDevice(): This method is not implemented on web', options);
    return { success: false };
  }

  async downloadDives(options: DownloadOptions): Promise<{ dives: DiveLog[] }> {
    console.warn('LibDC.downloadDives(): This method is not implemented on web', options);
    return { dives: [] };
  }

  async disconnectDevice(): Promise<{ success: boolean }> {
    console.warn('LibDC.disconnectDevice(): This method is not implemented on web');
    return { success: false };
  }
}