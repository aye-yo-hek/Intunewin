# 🚀 Win32 App Update Guide - Upload Instructions

## 📦 **Files to Upload to Your Existing Win32 Apps**

### **Updated Packages Available:**
- **AXCodeSetup-UPDATED.intunewin** (146.97 MB) - ✅ Ready
- **Python314-UPDATED.intunewin** (28.26 MB) - ✅ Ready

---

## 📋 **Step-by-Step Upload Process**

### **For AXCodeSetup Win32 App:**

1. **Navigate to Microsoft Endpoint Manager**
   - Go to: https://endpoint.microsoft.com
   - Navigate: **Apps** → **Windows** → **All apps**

2. **Find Your Existing AXCodeSetup App**
   - Look for your previously deployed AXCodeSetup application
   - Click on the app name to open it

3. **Update the Package**
   - Click **Properties** in the left menu
   - Find **App package file** section
   - Click **Edit** (pencil icon)
   - Click **Select app package file**
   - Browse and select: `AXCodeSetup-UPDATED.intunewin`
   - Click **OK** to upload

4. **Verify Configuration** (should remain the same, but double-check):
   - **Install command:** `install.cmd`
   - **Uninstall command:** `uninstall.cmd`
   - **Install behavior:** System

5. **Detection Rule** (IMPORTANT - May Need Update):
   - **Current detection method:** Check what you have configured
   - **Recommended update:** Use **Custom script** with `detect.ps1`
   - **Alternative:** Manual rule - File exists at `%LOCALAPPDATA%\Programs\AX Code\AX Code.exe`

6. **Save Changes**
   - Click **Review + save**
   - Click **Save**

---

### **For Python314 Win32 App:**

1. **Navigate to Your Python314 App**
   - Same process as above
   - Find your Python314 application

2. **Update the Package**
   - **Properties** → **App package file** → **Edit**
   - Upload: `Python314-UPDATED.intunewin`

3. **Verify Configuration:**
   - **Install command:** `install.cmd`
   - **Uninstall command:** `uninstall.cmd`
   - **Install behavior:** System

4. **Detection Rule** (IMPORTANT):
   - **Recommended:** File exists at `%ProgramFiles%\Python314\python.exe`
   - **Alternative:** Custom script with `detect.ps1`

5. **Save Changes**

---

## 🔍 **Key Improvements in Updated Packages**

### **What Changed Inside the .intunewin Files:**

✅ **install.cmd** - Simplified from 47 lines to 4 lines  
✅ **Proper installer parameters** - Fixed 0x80070001 error  
✅ **File-based detection** - More reliable than registry  
✅ **Self-contained structure** - No external dependencies  

### **Expected Results After Upload:**

- ❌ **No more 0x80070001 errors**
- ⚡ **Faster installations** (no timeouts)
- 🎯 **Reliable detection**
- 📊 **Better success rates**

---

## 🧪 **Testing the Updates**

### **Before Deploying to All Users:**

1. **Deploy to Test Group First**
   - Create a small test group (5-10 devices)
   - Assign the updated apps as **Required**
   - Monitor for 24-48 hours

2. **Monitor Installation Results**
   - Check **Device install status** in Intune
   - Look for reduced error rates
   - Verify apps appear in device inventory

3. **Success Indicators:**
   - Installation success rate > 95%
   - No 0x80070001 errors
   - Consistent detection results

### **If Issues Persist:**

1. **Check Installation Commands**
   - Verify install command is still: `install.cmd`
   - Ensure detection rule points to correct file paths

2. **Review Device Logs**
   - Check Intune Management Extension logs
   - Look for improved error messages

3. **Validate Detection Scripts**
   - Ensure detection method uses file existence
   - Test detection scripts manually on devices

---

## 📊 **Before vs After Comparison**

| Aspect | Before (Old Package) | After (Updated Package) |
|--------|---------------------|------------------------|
| Install Script | 47 lines with complex logic | 4 lines direct execution |
| Installer Params | Generic `/S` (causes 0x80070001) | Proper `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` |
| Detection Method | Custom registry entries | File existence check |
| Error Handling | Complex timeout/retry logic | Direct execution with proper params |
| Dependencies | External "exe files" folder | Self-contained packages |

---

## 🎯 **Upload Checklist**

- [ ] Upload `AXCodeSetup-UPDATED.intunewin` to existing AXCodeSetup app
- [ ] Upload `Python314-UPDATED.intunewin` to existing Python314 app  
- [ ] Verify install commands remain: `install.cmd`
- [ ] Update detection rules to file-based methods
- [ ] Test with small pilot group first
- [ ] Monitor for reduced error rates
- [ ] Deploy to production after successful testing

---

## 🚨 **Critical Notes**

1. **Don't change app names** - Update the existing apps to preserve assignments
2. **Test first** - Always pilot with a small group before production
3. **Monitor closely** - Watch for improved success rates
4. **Keep old packages** - As backup until confirmed working

The updated packages follow Andrew Taylor's best practices and should eliminate the 0x80070001 errors you were experiencing!