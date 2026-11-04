"""Adds Bluetooth permissions to the platform folders made by `flutter create`."""
import re, pathlib

# ---- Android ----
m = pathlib.Path("android/app/src/main/AndroidManifest.xml")
t = m.read_text()
perms = """    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>
"""
if "BLUETOOTH_SCAN" not in t:
    t = t.replace("<application", perms + "    <application", 1)
    if "xmlns:tools" not in t:
        t = t.replace("<manifest ", '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
    t = t.replace('android:usesPermissionFlags="neverForLocation"',
                  'android:usesPermissionFlags="neverForLocation" tools:targetApi="s"')
    m.write_text(t)

# ---- iOS ----
p = pathlib.Path("ios/Runner/Info.plist")
t = p.read_text()
if "NSBluetoothAlwaysUsageDescription" not in t:
    add = """\t<key>NSBluetoothAlwaysUsageDescription</key>
\t<string>CyberDrive needs Bluetooth to control your car.</string>
\t<key>NSBluetoothPeripheralUsageDescription</key>
\t<string>CyberDrive needs Bluetooth to control your car.</string>
"""
    idx = t.rfind("</dict>")
    t = t[:idx] + add + t[idx:]
    p.write_text(t)
print("platform files patched")
