Here is the consolidated, battle-tested blueprint from our session. By using these exact files and sequences, you will completely bypass the file-size crashes, terminal bugs, and bootloops we solved.

---

## Phase 1: The Required Files

Before typing a single command, you must gather these specific files. We used two Fastboot builds because each one avoided a different bug.

| File Name | Purpose | Source / Note |
| --- | --- | --- |
| **Platform Tools v34.0.4** | VBMeta patching only | Required for `--disable-verity --disable-verification flash vbmeta`; newer Fastboot builds failed with the `AVB_MAGIC` offset bug. |
| **Current / newer Platform Tools** | System flash, erase, wipe, reboot | Use the newer `platformtools` Fastboot for normal flashing and `-w`; v34 handled VBMeta correctly but was less reliable for wipe/format on this device. |
| **`vbmeta.img`** | Disables Verified Boot | Extracted from the official Google AOSP Android 10 GSI zip. |
| **`system-quack-arm64-ab-gapps.img`** | The Operating System | Android 10 Phhusson GSI. Must be the **`ab`** version (System-as-Root layout) and **`gapps`** version (includes Play Store). |
| **WSL `img2simg`** | Raw-to-sparse converter | Needed when the extracted `system.img` starts with `00 00 00 00` instead of sparse magic `3A FF 26 ED`. Install in WSL with `sudo apt install android-sdk-libsparse-utils`. |

> ⚠️ **Important:** The commands below use explicit PowerShell variables, so the files do not have to be in the current folder. Adjust the paths if your folders differ.

---

## Phase 2: The Flashing Procedure

Connect your phone to your computer, turn it off, and hold **Power + Volume Up** until the screen reads `FASTBOOT`. Open a Windows PowerShell window and execute this layout.

0. **Initialize PowerShell Paths:** Step 0.
Use v34 only for VBMeta, and use the newer Fastboot for the rest of the process.

```powershell
$FastbootR34 = 'C:\Temp\K9\platform-tools_r34.0.4-windows\fastboot.exe'
$FastbootNew = 'C:\Temp\K9\platformtools\fastboot.exe'
$Vbmeta = 'C:\Temp\K9\platform-tools_r34.0.4-windows\vbmeta.img'
$SystemRaw = 'C:\Temp\K9\platformtools\system-quack-arm64-ab-gapps.img'
$System = $SystemRaw
```

0.5. **Verify or Convert the System Image:** Step 0.5.
Fastboot on Windows crashed on large raw ext4 images. If the image is raw, convert it to Android sparse format with WSL before flashing.

```powershell
Format-Hex $SystemRaw -Count 4
```

If the first bytes are `3A FF 26 ED`, the image is already sparse and `$System = $SystemRaw` is correct.

If the first bytes are `00 00 00 00`, confirm it is raw ext4:

```powershell
Format-Hex $SystemRaw -Offset 1080 -Count 2
```

If that shows `53 EF`, convert it from WSL:

```powershell
wsl img2simg "/mnt/c/Temp/K9/platformtools/system-quack-arm64-ab-gapps.img" "/mnt/c/Temp/K9/platformtools/system-quack-arm64-ab-gapps-sparse.img"
$System = 'C:\Temp\K9\platformtools\system-quack-arm64-ab-gapps-sparse.img'
Format-Hex $System -Count 4
```

The converted sparse file should start with `3A FF 26 ED`.

1. **Verify Connection:** Step 1.
Ensure Windows completely recognizes the device over USB before executing payloads.

```powershell
& $FastbootNew devices

```

**Expected Output:**

```text
OUKITELK90000693         fastboot

```


2. **Disable Android Verified Boot (AVB):** Step 2.
This strips out the hardware block looking for factory digital signatures. *Must be executed using Fastboot v34.0.4 because newer Fastboot builds failed with `Failed to find AVB_MAGIC at offset: 0` on this device.*

```powershell
& $FastbootR34 --disable-verity --disable-verification flash vbmeta $Vbmeta

```

**Expected Output:**

```text
Rewriting vbmeta struct at offset: 0
Sending 'vbmeta' (4 KB)                            OKAY [  0.038s]
Writing 'vbmeta'                                   OKAY [  0.014s]
Finished. Total time: 0.131s

```


3. **Wipe Old System Blocks:** Step 3.
Clear out the old OS partition fully to ensure no corrupted block fragmentation occurs.

```powershell
& $FastbootNew erase system

```

**Expected Output:**

```text
Erasing 'system'                                   OKAY [  0.113s]
Finished. Total time: 0.138s

```


4. **Flash the Android 10 GSI System Image:** Step 4.
Flash the core Operating System. We use the `-S 100M` flag to slice the layout dynamically into 100MB chunks, preventing the Windows memory allocation error.

```powershell
& $FastbootNew -S 100M flash system $System

```

**Expected Output:**

```text
Warning: skip copying system image avb footer due to sparse image.
Sending sparse 'system' 1/13 (131068 KB)            OKAY [ 43.113s]
Writing 'system'                                   OKAY [  1.731s]
...
Sending sparse 'system' 13/13 (126460 KB)           OKAY [ 41.594s]
Writing 'system'                                   OKAY [  1.756s]
Finished. Total time: 581.162s

```


5. **Perform Factory Reset & Clear Cache:** Step 5.
Wipe out leftover user configurations and system metadata caches from the previous OS to prevent a runtime framework crash on boot.

```powershell
& $FastbootNew -w

```

**Expected Output:**

```text
Erasing 'userdata'                                 OKAY [  0.043s]
Formatting 'userdata' via mke2fs...                OKAY 
Erasing 'cache'                                    OKAY [  0.024s]
Formatting 'cache' via mke2fs...                   OKAY
Finished. Total time: 1.456s

```


6. **Boot Into Android:** Step 6.
Command the phone's bootloader to hand execution over to the newly written system framework.

```powershell
& $FastbootNew reboot

```

**Expected Output:**

```text
Rebooting                                          OKAY [  0.008s]
Finished. Total time: 0.011s

```


---

## Phase 3: Post-Boot Google Marketplace Activation

Because this is a custom, uncertified GSI, the Google Play Services framework might throw a "Device is not certified" alert when you hit the setup screen. Use this built-in bypass to open access:

1. Proceed through the Android 10 setup wizard. If it asks you to sign into a Google Account and locks up, **disconnect from Wi-Fi** to skip the login phase and proceed directly to the home screen.
2. Open **Settings** -> **Phh Treble Settings**.
3. Tap on **GMS / Android Features**.
4. Tap **Securize**. This masks your custom configuration signature layers and causes Google Play Services to treat your device as a certified stock phone.
5. Restart your phone, reconnect to Wi-Fi, open the Play Store, and sign in. All features are now active!
