import Foundation
import IOKit.hid

print("🚀 Ajazz Native Clock Daemon started.")
print("⚙️  Mode: Instant connection detection + 15s periodic sync.")

// 1. Initialize the HID Manager
let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, nil)
IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

// Global variable for Debounce to prevent duplicate sends to multiple interfaces
var lastSyncTime = Date.distantPast

// 2. Core function to build payload and send time
func syncTime(to device: IOHIDDevice) -> Bool {
    let now = Date()
    
    // DEBOUNCE: Ignore if we already synced successfully less than 2 seconds ago
    if now.timeIntervalSince(lastSyncTime) < 2.0 { return false }
    
    let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
    guard openResult == kIOReturnSuccess else { return false }
    
    defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }
    
    var payload = [UInt8](repeating: 0, count: 64)
    payload[0] = 0x28 // Report ID
    payload[7] = 0xd7 // Command
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
    
    if let year = components.year {
        payload[8] = UInt8((year >> 8) & 0xFF)
        payload[9] = UInt8(year & 0xFF)
    }
    payload[10] = UInt8(components.month ?? 1)
    payload[11] = UInt8(components.day ?? 1)
    payload[12] = UInt8(components.hour ?? 0)
    payload[13] = UInt8(components.minute ?? 0)
    payload[14] = UInt8(components.second ?? 0)
    
    let reportId = CFIndex(payload[0])
    let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, reportId, payload, payload.count)
    
    if result == kIOReturnSuccess {
        lastSyncTime = Date() // Record the exact time of successful sync
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        print("✅ [\(formatter.string(from: lastSyncTime))] Time synced successfully!")
        return true
    }
    
    return false
}

// 3. Function for the timer to scan already connected devices
func syncAllConnected() {
    guard let devicesSet = IOHIDManagerCopyDevices(manager) else { return }
    guard let nsSet = devicesSet as? NSSet,
          let devices = nsSet.allObjects as? [IOHIDDevice] else { return }
    
    for device in devices {
        if let productProperty = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString),
           let productStr = productProperty as? String {
            
            let upper = productStr.uppercased()
            if upper.contains("AJAZZ") && upper.contains("2.4G") {
                if syncTime(to: device) {
                    return // Stop iterating once successfully synced
                }
            }
        }
    }
}

// 4. Callback for INSTANT reaction upon physical connection
let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
    if let productProperty = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString),
       let productStr = productProperty as? String {
        
        let upper = productStr.uppercased()
        if upper.contains("AJAZZ") && upper.contains("2.4G") {
            
            // Give the dock firmware 1.5 seconds to boot up its screen before sending data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                _ = syncTime(to: device)
            }
        }
    }
}

// Register the connection callback
IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, nil)

// 5. Initial sync on startup
syncAllConnected()

// 6. Failsafe timer: Syncs every 15 seconds (handles sleep/wake cycles perfectly)
let timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
    syncAllConnected()
}

RunLoop.current.add(timer, forMode: .default)
CFRunLoopRun()
