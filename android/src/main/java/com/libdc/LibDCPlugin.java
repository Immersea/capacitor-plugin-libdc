package com.libdc;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import org.libdivecomputer.Context;
import org.libdivecomputer.Descriptor;
import org.libdivecomputer.Device;
import org.libdivecomputer.Serial;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@CapacitorPlugin(
    name = "LibDC",
    permissions = {
        @Permission(strings = { Manifest.permission.BLUETOOTH }, alias = "bluetooth"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_ADMIN }, alias = "bluetooth_admin"),
        @Permission(strings = { Manifest.permission.ACCESS_FINE_LOCATION }, alias = "location"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_SCAN }, alias = "bluetooth_scan"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_CONNECT }, alias = "bluetooth_connect")
    }
)
public class LibDCPlugin extends Plugin {
    private static final String TAG = "LibDCPlugin";
    
    private LibDCImplementation implementation;
    private BluetoothAdapter bluetoothAdapter;
    
    @Override
    public void load() {
        implementation = new LibDCImplementation(getContext());
        
        // Initialize Bluetooth adapter
        BluetoothManager bluetoothManager = (BluetoothManager) getContext().getSystemService(Context.BLUETOOTH_SERVICE);
        if (bluetoothManager != null) {
            bluetoothAdapter = bluetoothManager.getAdapter();
        }
    }
    
    @PluginMethod
    public void initialize(PluginCall call) {
        // Check if Bluetooth is supported
        if (bluetoothAdapter == null) {
            call.reject("Bluetooth is not supported on this device");
            return;
        }
        
        // Check if Bluetooth is enabled
        if (!bluetoothAdapter.isEnabled()) {
            call.reject("Bluetooth is not enabled");
            return;
        }
        
        // Initialize the implementation
        try {
            implementation.initialize();
            JSObject result = new JSObject();
            result.put("success", true);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to initialize: " + e.getMessage(), e);
        }
    }
    
    @PluginMethod
    public void scanDevices(PluginCall call) {
        // Check permissions first
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!hasRequiredPermissions()) {
                requestPermissionForAlias("bluetooth_scan", call, "scanPermsCallback");
                return;
            }
        } else {
            if (!hasRequiredPermissions()) {
                requestPermissionForAlias("location", call, "scanPermsCallback");
                return;
            }
        }
        
        doScan(call);
    }
    
    @PermissionCallback
    private void scanPermsCallback(PluginCall call) {
        if (hasRequiredPermissions()) {
            doScan(call);
        } else {
            call.reject("Permission is required to scan for devices");
        }
    }
    
    private void doScan(PluginCall call) {
        try {
            List<LibDCImplementation.DeviceInfo> devices = implementation.scanDevices();
            
            JSObject result = new JSObject();
            JSArray deviceArray = new JSArray();
            
            for (LibDCImplementation.DeviceInfo device : devices) {
                JSObject deviceObj = new JSObject();
                deviceObj.put("name", device.getName() != null ? device.getName() : "");
                deviceObj.put("address", device.getAddress());
                if (device.getFamily() != null) {
                    deviceObj.put("family", device.getFamily());
                }
                if (device.getRssi() != null) {
                    deviceObj.put("rssi", device.getRssi());
                }
                deviceArray.put(deviceObj);
            }
            
            result.put("devices", deviceArray);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to scan devices: " + e.getMessage(), e);
        }
    }
    
    @PluginMethod
    public void connectDevice(PluginCall call) {
        // Check permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!hasRequiredPermissions()) {
                requestPermissionForAlias("bluetooth_connect", call, "connectPermsCallback");
                return;
            }
        }
        
        String address = call.getString("address");
        if (address == null) {
            call.reject("Device address is required");
            return;
        }
        
        String family = call.getString("family");
        Integer timeout = call.getInt("timeout");
        
        try {
            boolean success = implementation.connectDevice(address, family, timeout);
            JSObject result = new JSObject();
            result.put("success", success);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to connect to device: " + e.getMessage(), e);
        }
    }
    
    @PermissionCallback
    private void connectPermsCallback(PluginCall call) {
        if (hasRequiredPermissions()) {
            connectDevice(call);
        } else {
            call.reject("Permission is required to connect to devices");
        }
    }
    
    @PluginMethod
    public void downloadDives(PluginCall call) {
        Boolean forceAll = call.getBoolean("forceAll", false);
        String fingerprint = call.getString("fingerprint");
        
        try {
            List<LibDCImplementation.DiveLog> dives = implementation.downloadDives(forceAll, fingerprint);
            
            JSObject result = new JSObject();
            JSArray divesArray = new JSArray();
            
            for (LibDCImplementation.DiveLog dive : dives) {
                JSObject diveObj = new JSObject();
                diveObj.put("id", dive.getId());
                diveObj.put("fingerprint", dive.getFingerprint());
                diveObj.put("datetime", dive.getDatetime());
                diveObj.put("data", dive.getData());
                
                if (dive.getMaxDepth() != null) {
                    diveObj.put("maxDepth", dive.getMaxDepth());
                }
                
                if (dive.getDuration() != null) {
                    diveObj.put("duration", dive.getDuration());
                }
                
                // Add additional info
                Map<String, Object> additionalInfo = dive.getAdditionalInfo();
                if (additionalInfo != null) {
                    for (Map.Entry<String, Object> entry : additionalInfo.entrySet()) {
                        diveObj.put(entry.getKey(), entry.getValue());
                    }
                }
                
                divesArray.put(diveObj);
            }
            
            result.put("dives", divesArray);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to download dives: " + e.getMessage(), e);
        }
    }
    
    @PluginMethod
    public void disconnectDevice(PluginCall call) {
        try {
            boolean success = implementation.disconnectDevice();
            JSObject result = new JSObject();
            result.put("success", success);
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Failed to disconnect device: " + e.getMessage(), e);
        }
    }
    
    private boolean hasRequiredPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return hasPermission(Manifest.permission.BLUETOOTH_SCAN) && 
                   hasPermission(Manifest.permission.BLUETOOTH_CONNECT);
        } else {
            return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) && 
                   hasPermission(Manifest.permission.BLUETOOTH) && 
                   hasPermission(Manifest.permission.BLUETOOTH_ADMIN);
        }
    }
}