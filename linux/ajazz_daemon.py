import hid
import time
from datetime import datetime

def is_target_device(device_dict):
    """
    Checks if the device is an Ajazz 2.4G receiver by its product string.
    This makes the script universal for different Ajazz models (e.g., AJ179, AJ199, AJ159)
    without needing to hardcode specific VIDs and PIDs.
    """
    prod_string = device_dict.get('product_string') or ""
    prod_string = prod_string.upper()
    
    # Check if the name contains both "AJAZZ" and "2.4G" (like "AJAZZ 2.4G 8K")
    if "AJAZZ" in prod_string and "2.4G" in prod_string:
        return True
        
    return False

def sync_time():
    """Finds the device by name and sends the current time payload."""
    success = False
    
    for device_dict in hid.enumerate():
        if is_target_device(device_dict):
            try:
                device = hid.device()
                device.open_path(device_dict['path'])
                
                now = datetime.now()
                payload = [0x00] * 64
                payload[0] = 0x28
                payload[7] = 0xd7
                
                # Year (Big Endian)
                payload[8] = now.year >> 8
                payload[9] = now.year & 0xFF
                
                payload[10] = now.month
                payload[11] = now.day
                payload[12] = now.hour
                payload[13] = now.minute
                payload[14] = now.second
                
                # A single USB receiver usually exposes multiple HID interfaces (mouse, kb, vendor).
                # The feature report will only succeed on the vendor-specific interface.
                device.send_feature_report(payload)
                device.close()
                success = True
            except Exception:
                # Ignore errors for interfaces that don't accept feature reports
                pass
                
    return success

def main():    
    while True:
        try:
            # Check if any Ajazz dock is currently connected
            is_connected = any(is_target_device(d) for d in hid.enumerate())
            
            # If the dock was just connected (or the hub was switched to Mac)
            if is_connected:
                time.sleep(1.5)  # Give macOS a moment to fully initialize the USB device
                sync_time()

        except Exception:
            pass
            
        # Sleep for 5 seconds to prevent CPU usage
        time.sleep(5)

if __name__ == "__main__":
    main()