# ⚠️ INTUNE UPLOAD FIX - Quick Guide

## ✅ Package Copied to Your Desktop

**File:** `install-enhanced.intunewin`

**Location:** `C:\Users\hhernandez\OneDrive - cPacket Networks\Desktop\`

---

## 🔧 Most Common Fix (Try This First)

### Use Microsoft Edge Browser

1. **Close all browsers**

2. **Open Microsoft Edge** (not Chrome/Firefox)

3. **Clear cache:** Press `Ctrl + Shift + Delete`
   - Select "All time"
   - Check "Cached images and files"
   - Click "Clear now"

4. **Go to Intune:** https://intune.microsoft.com

5. **Navigate:** Apps → Windows → + Add → Windows app (Win32)

6. **Upload from Desktop:**
   - Click "Select app package file"
   - Browse to **Desktop**
   - Select `install-enhanced.intunewin`
   - Click Open

7. **Wait patiently** (2-5 minutes)
   - Don't close browser
   - Don't refresh page
   - Watch for green checkmark

---

## 🚨 If Upload Still Fails

### Try These in Order:

**Option 1: Different Network**
- Disable VPN if connected
- Try from different WiFi network
- Use mobile hotspot
- Use wired ethernet connection

**Option 2: InPrivate/Incognito Mode**
1. Open Edge in InPrivate: `Ctrl + Shift + N`
2. Go to https://intune.microsoft.com
3. Try upload again

**Option 3: Run Browser as Admin**
1. Right-click Microsoft Edge
2. Select "Run as administrator"
3. Try upload again

**Option 4: Different Browser**
- Try Microsoft Edge (Chromium)
- Try Google Chrome
- Avoid Firefox for Intune uploads

**Option 5: Wait and Retry**
- Microsoft services might be slow
- Wait 15-30 minutes
- Try again during off-peak hours

---

## 📊 What to Watch During Upload

✅ **Good signs:**
- Progress bar appears
- Percentage increases: 0% → 25% → 50% → 75% → 100%
- Green checkmark appears
- "Click Next" button becomes available

❌ **Bad signs:**
- Stuck at 0% for more than 2 minutes
- Stuck at 50% for more than 5 minutes
- Error message appears
- Page becomes unresponsive

**If stuck:** Wait 5 minutes before closing browser

---

## 💡 Pro Tips

1. **Best browser:** Microsoft Edge (best compatibility)
2. **Best time:** During work hours (Microsoft services faster)
3. **Best network:** Stable wired connection
4. **File location:** Desktop (not OneDrive syncing folder)
5. **Patience:** Can take up to 10 minutes for large files

---

## 🎯 Complete Settings (Copy & Paste Ready)

Once upload succeeds, use these settings:

### App Information
```
Name: Adobe Acrobat DC (64-bit) - Cloud & AI Disabled
Publisher: Adobe Inc.
App Version: 21.001.20135
```

### Program
```
Install command: install-enhanced.cmd
Uninstall command: msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
Install behavior: System
```

### Requirements
```
OS Architecture: 64-bit
Minimum OS: Windows 10 1607
```

### Detection Rules
```
Rule type: MSI
MSI product code: {AC76BA86-1033-FFFF-7760-BC15014EA700}
```

---

## 📞 Still Having Issues?

**Check Microsoft 365 Service Health:**
https://admin.microsoft.com/ServiceHealth

**Common Error Codes:**
- `504 Gateway Timeout` → Try different network
- `413 Payload Too Large` → Package too big (but yours is only 3.39 MB - should be fine)
- `Connection Reset` → Network/firewall issue

---

## ✅ Success Checklist

After successful upload:

- [ ] Green checkmark appeared
- [ ] Package information shows correct size
- [ ] Clicked "Next"
- [ ] Filled in App Information
- [ ] Configured Program settings
- [ ] Set Detection rules
- [ ] Assigned to pilot group
- [ ] Clicked "Create"

---

**Good luck! The package is on your Desktop and ready to upload.** 🚀

**Package:** `C:\Users\hhernandez\OneDrive - cPacket Networks\Desktop\install-enhanced.intunewin`

**Portal:** https://intune.microsoft.com
