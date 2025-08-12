#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin
CAP_PLUGIN(LibDCPlugin, "LibDC",
           CAP_PLUGIN_METHOD(initialize, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(scanDevices, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(connectDevice, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(downloadDives, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(disconnectDevice, CAPPluginReturnPromise);
)