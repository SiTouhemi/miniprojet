# QR Code System User Guide

## For Students

### How to Display Your QR Code

1. **Make a Reservation**
   - Navigate to "Reserve Meal" from the home screen
   - Select your desired meal time slot
   - Complete the payment
   - Wait for confirmation

2. **Access Your QR Code**
   - Go to "My Reservations" from the home screen
   - Find your confirmed reservation
   - Tap the green "Show QR Code" button
   - Your QR code will be generated automatically

3. **At the Restaurant**
   - Open your QR code before arriving
   - Keep your screen brightness high for easy scanning
   - Show the QR code to the staff member
   - Wait for the green checkmark confirmation

### QR Code Features

- **Auto-Generation**: QR codes are created automatically when you tap "Show QR Code"
- **Expiry Timer**: Shows how many minutes until the QR code expires
- **Regeneration**: If your QR code expires, tap "Generate New QR" to create a fresh one
- **Screen Stay-On**: Your screen will stay on while displaying the QR code

### Important Notes

- QR codes expire 30 minutes after your meal time
- Each QR code can only be used once
- Keep your phone charged before going to the restaurant
- If you have network issues, the QR code will still work (it's stored locally)

### Troubleshooting

**Problem**: QR code won't generate
- **Solution**: Check your internet connection and try again

**Problem**: QR code expired
- **Solution**: Tap "Generate New QR" to create a fresh code

**Problem**: Staff says QR code is invalid
- **Solution**: Make sure you're showing the correct reservation and the code hasn't been used already

## For Staff

### How to Scan QR Codes

1. **Open the Scanner**
   - From the Staff Home screen
   - Tap "Scanner QR Code" (blue button)
   - Allow camera permissions if prompted

2. **Scan a Student's QR Code**
   - Point your camera at the student's QR code
   - Keep the QR code within the white brackets
   - The system will scan automatically
   - Wait for validation (usually under 2 seconds)

3. **Review Results**
   - **Green Screen**: Reservation is valid
     - Student name and class displayed
     - Meal details shown
     - Tap "Scan Another" to continue
   
   - **Red Screen**: Problem detected
     - Error message explains the issue
     - Common errors: Expired, Already Used, Invalid
     - Tap "Scan Another" to continue

### Scanner Features

- **Torch Toggle**: Tap the flashlight icon for low-light conditions
- **Camera Flip**: Switch between front and back cameras
- **Scan History**: Tap the history icon to view recent scans
- **Auto-Detection**: No need to press any button, scanning is automatic

### Common Scenarios

#### Valid Reservation
- Green success screen appears
- Student information displayed
- Reservation marked as "used" in database
- Student can proceed to get their meal

#### Expired QR Code
- Red error screen with "QR Code Expired" message
- Ask student to regenerate their QR code
- Student should tap "Generate New QR" in their app

#### Already Used
- Red error screen with "Reservation Already Used" message
- Check if student already picked up their meal
- Verify the reservation ID if needed

#### Invalid QR Code
- Red error screen with "Invalid QR Code" message
- QR code may be forged or corrupted
- Ask student to regenerate or contact support

### Best Practices

1. **Good Lighting**: Ensure adequate lighting for scanning
2. **Steady Hand**: Hold the phone steady while scanning
3. **Distance**: Keep phone 15-30cm from the QR code
4. **Check Details**: Always verify student name matches their ID
5. **Scan History**: Review history periodically for audit purposes

### Troubleshooting

**Problem**: Camera won't open
- **Solution**: Check camera permissions in phone settings

**Problem**: QR codes won't scan
- **Solution**: 
  - Clean your camera lens
  - Improve lighting conditions
  - Ask student to increase screen brightness
  - Try toggling the torch

**Problem**: Slow scanning
- **Solution**: 
  - Close other apps to free up memory
  - Restart the scanner
  - Check internet connection

## Security Features

### For Students
- Your QR code is cryptographically signed
- Cannot be forged or duplicated
- Expires automatically for security
- One-time use only

### For Staff
- All scans are logged with timestamp
- Invalid QR codes are automatically rejected
- Tampered QR codes are detected
- Audit trail maintained for all validations

## Support

### Common Questions

**Q: Can I use the same QR code for multiple meals?**
A: No, each reservation has its own unique QR code.

**Q: What if I lose my phone?**
A: Log in on another device and access your reservations to display the QR code.

**Q: Can I share my QR code with friends?**
A: No, QR codes are tied to your student account and can only be used once.

**Q: What if the scanner is not working?**
A: Staff can manually verify your reservation using your student ID and reservation ID.

**Q: How early can I generate my QR code?**
A: You can generate it anytime after your reservation is confirmed, but it will expire 30 minutes after your meal time.

## Technical Details

### QR Code Contents
- Reservation ID
- Student information
- Meal details
- Expiry timestamp
- Security hash

### Validation Process
1. QR code scanned by staff
2. Format validation
3. Security hash verification
4. Expiry check
5. Duplicate use check
6. Database update
7. Result display

### Privacy
- QR codes contain only necessary information
- No sensitive data exposed
- Secure transmission
- Audit logs protected

## Emergency Procedures

### If QR System is Down

**For Students:**
- Have your reservation ID ready
- Show your student ID card
- Staff will manually verify your reservation

**For Staff:**
- Use manual verification process
- Check reservation list on admin dashboard
- Record manual validations for later audit
- Contact technical support

### Contact Information

- **Technical Support**: [support email]
- **Restaurant Manager**: [manager contact]
- **IT Department**: [IT contact]

---

**Last Updated**: January 4, 2025
**Version**: 1.0
