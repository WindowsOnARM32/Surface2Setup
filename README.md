# Surface2Setup
Setup Windows RT 10 Preview on Surface 2

Features:

1. Support installing both the original Windows RT 8.1 and a customized Windows RT 10 from recovery
2. Contains the necessary parts to disable Secure Boot (potentially could be run in the recovery directly instead of Windows RT, although untested since my device is already unlocked)
3. Post installation setup  

# Folder structure

    USB Drive
    ├───Boot
    ├───EFI
    ├───sources
    ├───WOA
    │   └───Office
    └───setup.cmd

# Create installation meda

## 1. Prepare

Go to Microsoft's [Surface Recovery Image Download](https://support.microsoft.com/en-us/surface-recovery-image) to download the recovery file.

Go to Alexenferman's [guide](https://www.alexenferman.com/articles/SurfaceRT/W10-OA-SurfaceRT.html) to download SecureBotPatch.zip.

Go to Alexenferman's [extra section](https://old.alexenferman.com/devices/extras-windows-10-oa) to download Office 2013 RT. You will need both the installer and the patch.

Go to DA Developer to download [Windows 10 Build 15035 Mod Kit](https://forum.xda-developers.com/t/windows-10-build-15035-mod-kit.4232301/). Appx Pack is optional.

## 2. Assemble

Following [Windows 10 Build 15035 Mod Kit](https://forum.xda-developers.com/t/windows-10-build-15035-mod-kit.4232301/) to create your own image. When the setup asks for Windows Setup Mode, select `Modified WIM Files Only (No Setup)`. The other 2 options will create unbootable installation media. We will call the output `install.wim`.

Grab an USB drive that's at least 4 GiB (you will need to delete and copy file in the middle of the installation), or perferably 8 GiB (can fit the recovery image, Windows 10 image, and patched image mentioned in Alexenferman's guide part 1). Create a MBR partition table, and create a FAT32 partition.

To do so in `diskpart`, enter the following commad:
```
list disk
rem CHANGE THE BELOW X TO YOUR USB DISK!!!
select disk X
clean
convert mbr
create partition primary
format quick fs=fat32
rem Change the below X if you want to mount to another drive letter
assign letter=X
exit
```

Copy the folowing files and folder from your recovery file to the drive:
```
.\Boot\
.\EFI\
.\sources\
.\bootmgr.efi
```

The `install.wim` in `.\sources\` is the recovery image. If you are using a 4 GiB drive, you can delete this file afer you have unlocked the Secure Boot.

Now copy `setup.cmd` from this repo to the drive as well, and create a new folder called `WOA` to store our own files.

From `SecureBotPatch.zip` copy `SecureBootDebug.efi` and `SecureBootDebugPolicy.p7b` to `.\WOA\`.

From `Office RT 2013.7z` copy Office to `.\WOA\Office\`. Makes sure `setup.exe` is located at `.\WOA\Office\setup.exe`.

From `Office RT 2013 patch.zip` copy 3 `LicenseSetData.*.xrm-ms` files to `.\WOA\`.

Optionally you can copy the forementioned patched Windows RT image to `.\WOA\` now. Our tool currently don't support this image since we cannot get Secure Boot unlocked using it. If you need to use this image please follow Alexenferman's [guide](https://www.alexenferman.com/articles/SurfaceRT/W10-OA-SurfaceRT.html).

Finally copy generated `install.wim` from Windows 10 Build 15035 Mod Kit to `.\WOA\`.

# Install Windows 10
Since I already unlocked my Surface 2, I can no longer test my script on a fresh locked device. As such it is recommended to first folow Alexenferman's [guide](https://www.alexenferman.com/articles/SurfaceRT/W10-OA-SurfaceRT.html).

2 things to note:

1st the patched Windows RT is useless on my Surface 2, and I unlocked my Secure Boot with the recovery image.

2nd from what I heard when you are installing the Secure Boot Debug Policy you have to copy it to the interal storage and you have to use an elevated shell to change directory into it before launching the script.

Now if someone wants to try our script, here are the steps:

1. Boot into Windows RT. Press Win+X, and click `Windows PowerShell (Admin)`, then type `d:\setup.cmd` and enter, type `1` and enter. Your Surface 2 will automatically reboot.

2. Boot into Windows RT. Press Win+X, and click `Windows PowerShell (Admin)`, then type `d:\setup.cmd` and enter, type `2` and enter. Your Surface 2 will automatically reboot. You will then see a `Secure Boot Debug Policy Applicator` window. Using volume buttons to select `Accept and install`, then pressing the Windows key to confirm. You can use the Windows button that's on the tablet.

3. Boot into Windows RT. Press Win+X, and click `Windows PowerShell (Admin)`, then type `d:\setup.cmd` and enter, type `3` and enter. Your Surface 2 will automatically reboot. When you see the Windows is rebooting, hold `Volume Down` button, until the Surface is showing the booting logo (white `Surface` on black background). You can then release the button and now you are booting into the USB drive.

4. In recovery mode, select your language and keyboard layout. Then click `Troubleshooting`, `Advanced Options`, and `Command Prompt`.

5. CHECK CHECK AND DOUBLE CHECK if you have `SecureBoot isn't configured correctly` on your screen's left bottom corner. Try again from step 2. If it still fails, try Alexenferman's [guide](https://www.alexenferman.com/articles/SurfaceRT/W10-OA-SurfaceRT.html).

6. In recovery's command prompt, type `d:\setup.cmd` and enter, type `4` and enter. Once the script is finished, close the command prompt, and click `Continue to Windows RT 10 Preview`. 

7. You will see the Windows Setup running, and eventually an error message:
```
Windows could not update the computer's boot configuration. Installation cannot proceed.
```
Press Shift+F10 or Fn+Shift+F10 to launch a command prompt, then type `d:\setup.cmd` and enter, type `5` and enter. You will need to click `OK` on the error message to reboot.

8. You will now boot into Windows RT 10. Finish your setup while ignoring the warnings. You will see 2 errors, one after you connect to the network, and one if you are trying to use a Microsoft account. Just ignore the first one and create a offline account.

9. Once the setup is completed and you are in the desktop, press Win+X, and click `Windows PowerShell (Admin)`, then type `d:\setup.cmd` and enter, type `6` and enter. This will finish the Windows installation. Make sure you have the internet connection or activation might fail.

Office activation could fail. I haven't looked into it yet.
