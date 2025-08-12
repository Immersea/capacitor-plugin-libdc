#import "BLEBridge.h"
#import <Foundation/Foundation.h>

static id<CoreBluetoothManagerProtocol> bleManager = nil;

void initializeBLEManager(void) {
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    bleManager = [CoreBluetoothManagerClass shared];
}

ble_object_t* createBLEObject(void) {
    ble_object_t* obj = malloc(sizeof(ble_object_t));
    obj->manager = (__bridge void *)bleManager;
    return obj;
}

void freeBLEObject(ble_object_t* obj) {
    if (obj) {
        free(obj);
    }
}

bool connectToBLEDevice(ble_object_t *io, const char *deviceAddress) {
    if (!io || !deviceAddress) {
        NSLog(@"Invalid parameters passed to connectToBLEDevice");
        return false;
    }
    
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    NSString *address = [NSString stringWithUTF8String:deviceAddress];
    
    bool success = [manager connectToDevice:address];
    if (!success) {
        NSLog(@"Failed to connect to device");
        return false;
    }
    
    // Wait for initial connection
    [NSThread sleepForTimeInterval:1.0];
    
    // Discover services
    success = [manager discoverServices];
    if (!success) {
        NSLog(@"Service discovery failed");
        [manager close];
        return false;
    }
    
    // Enable notifications
    success = [manager enableNotifications];
    if (!success) {
        NSLog(@"Failed to enable notifications");
        [manager close];
        return false;
    }
    
    return true;
}

bool discoverServices(ble_object_t *io) {
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    return [manager discoverServices];
}

bool enableNotifications(ble_object_t *io) {
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    return [manager enableNotifications];
}

dc_status_t ble_set_timeout(ble_object_t *io, int timeout) {
    return DC_STATUS_SUCCESS;
}

dc_status_t ble_ioctl(ble_object_t *io, unsigned int request, void *data, size_t size) {
    return DC_STATUS_UNSUPPORTED;
}

dc_status_t ble_sleep(ble_object_t *io, unsigned int milliseconds) {
    [NSThread sleepForTimeInterval:milliseconds / 1000.0];
    return DC_STATUS_SUCCESS;
}

dc_status_t ble_read(ble_object_t *io, void *buffer, size_t requested, size_t *actual)
{
    if (!io || !buffer || !actual) {
        return DC_STATUS_INVALIDARGS;
    }
    
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    uint8_t *outPtr = (uint8_t *)buffer;
    size_t total = 0;
    
    // Keep reading until we've gathered 'requested' bytes or no more data is arriving
    while (total < requested) {
        size_t needed = requested - total;
        // readDataPartial returns up to 'needed' bytes but might return fewer
        NSData *partialData = [manager readDataPartial:(int)needed];
        
        // If no data arrived this iteration, break out
        if (!partialData || partialData.length == 0) {
            break;
        }
        
        // Copy new data into our output buffer
        memcpy(outPtr + total, partialData.bytes, partialData.length);
        total += partialData.length;
    }
    
    // If we received no data at all, treat it as an I/O error
    if (total == 0) {
        *actual = 0;
        return DC_STATUS_IO;
    }
    
    // Otherwise, we successfully read some or all requested bytes
    *actual = total;
    return DC_STATUS_SUCCESS;
}

dc_status_t ble_write(ble_object_t *io, const void *data, size_t size, size_t *actual) {
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    NSData *nsData = [NSData dataWithBytes:data length:size];
    
    if ([manager writeData:nsData]) {
        *actual = size;
        return DC_STATUS_SUCCESS;
    } else {
        *actual = 0;
        return DC_STATUS_IO;
    }
}

dc_status_t ble_close(ble_object_t *io) {
    Class CoreBluetoothManagerClass = NSClassFromString(@"CoreBluetoothManager");
    id<CoreBluetoothManagerProtocol> manager = [CoreBluetoothManagerClass shared];
    [manager close];
    return DC_STATUS_SUCCESS;
}
