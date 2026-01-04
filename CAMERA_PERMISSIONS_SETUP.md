# Camera Permissions Setup Guide

## Overview
The QR scanner requires camera access to scan student QR codes. This guide explains how to configure camera permissions for both Android and iOS platforms.

## Android Setup

### 1. Update AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Add the following permissions inside the `<manifest>` tag (before `<application>`):

```xml
<!-- Camera permission for QR scanning -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Optional: For better camera performance -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### 2. Update build.gradle (if needed)

File: `android/app/build.gradle`

Ensure minimum SDK version is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for mobile_scanner
        targetSdkVersion 34
    }
}
```

### 3. Runtime Permission Handling

The `mobile_scanner` package automatically handles runtime permission requests on Android. When the user first opens the QR scanner, they will see a system dialog asking for camera permission.

## iOS Setup

### 1. Update Info.plist

File: `ios/Runner/Info.plist`

Add the following key-value pair inside the `<dict>` tag:

```xml
<!-- Camera permission description -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes for meal reservation validation</string>
```

You can customize the description text to match your app's language and tone. This message will be shown to users when requesting camera permission.

### 2. Update Podfile (if needed)

File: `ios/Podfile`

Ensure the platform version is at least iOS 12:

```ruby
platform :ios, '12.0'
```

### 3. Install Pods

After updating the Podfile, run:

```bash
cd ios
pod install
cd ..
```

## Testing Permissions

### Android Testing

1. **First Launch**:
   - Open the app
   - Navigate to QR Scanner
   - System dialog appears: "Allow [App Name] to take pictures and record video?"
   - Tap "Allow" or "While using the app"

2. **Permission Denied**:
   - If user denies permission, scanner shows error
   - User must go to Settings > Apps > [App Name] > Permissions > Camera
   - Enable camera permission manually

3. **Testing on Emulator**:
   - Android emulator supports camera simulation
   - Use virtual scene or webcam for testing

### iOS Testing

1. **First Launch**:
   - Open the app
   - Navigate to QR Scanner
   - System dialog appears: "[App Name] Would Like to Access the Camera"
   - Shows the custom description from Info.plist
   - Tap "OK" to allow

2. **Permission Denied**:
   - If user denies permission, scanner shows error
   - User must go to Settings > [App Name] > Camera
   - Toggle camera permission on

3. **Testing on Simulator**:
   - iOS simulator has limited camera support
   - Test on physical device for best results
   - Can use Xcode's camera simulation features

## Permission States

### Granted
- Scanner opens normally
- Camera preview visible
- QR codes can be scanned

### Denied
- Scanner shows error message
- Instructions to enable in settings
- Fallback to manual entry (if implemented)

### Not Determined (First Time)
- System permission dialog shown
- User must make a choice
- App remembers the choice

## Troubleshooting

### Android Issues

**Problem**: Camera permission dialog doesn't appear
- **Solution**: Check AndroidManifest.xml has correct permissions
- **Solution**: Ensure targetSdkVersion is 23 or higher for runtime permissions

**Problem**: "Camera permission denied" error
- **Solution**: Go to Settings > Apps > [App Name] > Permissions > Enable Camera

**Problem**: Black screen in scanner
- **Solution**: Check if another app is using the camera
- **Solution**: Restart the app
- **Solution**: Check device camera hardware

### iOS Issues

**Problem**: Permission dialog doesn't appear
- **Solution**: Check Info.plist has NSCameraUsageDescription
- **Solution**: Clean build folder and rebuild

**Problem**: "Camera access denied" error
- **Solution**: Go to Settings > [App Name] > Enable Camera

**Problem**: Crash when opening scanner
- **Solution**: Verify Info.plist syntax is correct
- **Solution**: Check iOS deployment target is 12.0 or higher

## Best Practices

### User Experience

1. **Explain Before Asking**:
   - Show a brief explanation before requesting permission
   - Explain why camera access is needed
   - Make it clear it's only for QR scanning

2. **Handle Denial Gracefully**:
   - Show clear error message
   - Provide instructions to enable in settings
   - Offer alternative methods (manual entry)

3. **Test Thoroughly**:
   - Test on multiple devices
   - Test permission denial scenarios
   - Test permission revocation

### Security

1. **Minimal Access**:
   - Only request camera when needed
   - Don't keep camera active in background
   - Release camera resources when done

2. **Privacy**:
   - Don't store camera images
   - Don't transmit camera data
   - Only process QR codes

3. **Compliance**:
   - Follow platform guidelines
   - Respect user privacy choices
   - Provide clear privacy policy

## Platform-Specific Notes

### Android

- **Permissions are persistent**: Once granted, permission persists until user revokes it
- **Background restrictions**: Camera cannot be used in background
- **Multiple cameras**: Can switch between front/back cameras
- **Torch support**: Can enable flashlight for low-light scanning

### iOS

- **Permissions are persistent**: Once granted, permission persists until user revokes it
- **Privacy-focused**: iOS is strict about camera usage
- **App Store review**: Must justify camera usage in review
- **Background restrictions**: Camera cannot be used in background

## Code Examples

### Checking Permission Status (Optional)

If you want to check permission status before opening scanner:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkCameraPermission() async {
  final status = await Permission.camera.status;
  
  if (status.isGranted) {
    return true;
  } else if (status.isDenied) {
    // Request permission
    final result = await Permission.camera.request();
    return result.isGranted;
  } else if (status.isPermanentlyDenied) {
    // Open app settings
    await openAppSettings();
    return false;
  }
  
  return false;
}
```

Note: The `mobile_scanner` package handles permissions automatically, so this is optional.

### Handling Permission Errors

```dart
try {
  // Open scanner
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => QRScannerWidget()),
  );
} catch (e) {
  if (e.toString().contains('permission')) {
    // Show permission error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('Please enable camera access in settings to scan QR codes.'),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
```

## Deployment Checklist

Before deploying to production:

- [ ] AndroidManifest.xml has camera permission
- [ ] Info.plist has NSCameraUsageDescription
- [ ] Tested on physical Android device
- [ ] Tested on physical iOS device
- [ ] Tested permission denial scenario
- [ ] Tested permission revocation scenario
- [ ] Error messages are user-friendly
- [ ] Privacy policy mentions camera usage
- [ ] App Store description mentions QR scanning

## Additional Resources

- [Android Camera Permissions](https://developer.android.com/training/permissions/requesting)
- [iOS Camera Permissions](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios)
- [mobile_scanner Package](https://pub.dev/packages/mobile_scanner)
- [Flutter Permission Handler](https://pub.dev/packages/permission_handler)

---

**Last Updated**: January 4, 2025
**Version**: 1.0
