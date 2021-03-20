@echo off
setlocal enableextensions
pushd "%~dp0"
call :main
popd
goto :eof

:main
call :show_main_menu
set /p MAIN_MENU_OPTION="Select an option: "

2>nul call :MAIN_MENU_OPTION_%MAIN_MENU_OPTION%
if errorlevel 1 call :MAIN_MENU_OPTION_DEFAULT
goto :MAIN_MENU_OPTION_END

::Install original Windows RT
:MAIN_MENU_OPTION_0
call :diskpart clean
echo Pause 15 second before next script...
::https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/diskpart-scripts-and-examples
ping 127.0.0.1 /n 15 > 0
call :diskpart format
mkdir T:\Recovery\WindowsRE\
copy .\sources\boot.wim T:\Recovery\WindowsRE\winre.wim
mkdir R:\RecoveryImage\
echo boot.wim > xcopy_exclude.txt
xcopy /e /exclude:xcopy_exclude.txt .\sources R:\RecoveryImage\
del xcopy_exclude.txt
call :dism .\sources\install.wim w
bcdboot x:\windows /s s:
bootrec /rebuildbcd
call :exit
goto :eof

::Disable UAC
:MAIN_MENU_OPTION_1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
call :reboot
goto :eof

::Install Secure Boot Debug Policy
:MAIN_MENU_OPTION_2
manage-bde -protectors %systemdrive% -disable
mountvol s: /s
copy /Y .\WOA\SecureBootDebug.efi s:\EFI\Microsoft\Boot\SecurebootDebug.efi
copy /Y .\WOA\SecureBootDebugPolicy.p7b s:\SecureBootDebugPolicy.p7b
set var={9809d174-88ef-11e1-8346-00155de8c610}
bcdedit /create "%var%" /d "KitsPolicyTool" /application osloader
bcdedit /set "%var%" path "\EFI\Microsoft\Boot\SecureBootDebug.efi"
bcdedit /set "%var%" loadoptions Install
bcdedit /set "%var%" device partition=S:
bcdedit /set {bootmgr} bootsequence "%var%"
mountvol s: /d
call :reboot
goto :eof

::Disable Secure Boot
:MAIN_MENU_OPTION_3
bcdedit /set {bootmgr} testsigning on
bcdedit /set {default} testsigning on
call :reboot
goto :eof

::Install Windows 10
:MAIN_MENU_OPTION_4
call :diskpart mount
echo Pause 15 second before next script...
::https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/diskpart-scripts-and-examples
ping 127.0.0.1 /n 15 > 0
call :diskpart win10
bcdboot x:\windows /s s:
call :dism .\WOA\surface2_win10_zh_cn_new.wim
bootrec /rebuildbcd
bcdedit /set {bootmgr} testsigning on
bcdedit /set {default} testsigning on
call :exit
goto :eof

::Bypass Windows 10 setup.exe error
:MAIN_MENU_OPTION_5
reg add "HKLM\SYSTEM\Setup\Status\ChildCompletion" /v setup.exe /t REG_DWORD /d 3 /f
call :exit
goto :eof

::Set up Windows 10
:MAIN_MENU_OPTION_6
echo Disable expiration warning
takeown /f C:\Windows\System32\LicensingUI.exe
explorer /select,"C:\Windows\System32\LicensingUI.exe"
echo Set page file size to 2047 MiB
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=2047,MaximumSize=2047
echo Activate Windows 10
cscript //nologo c:\windows\system32\slmgr.vbs /upk
cscript //nologo c:\windows\system32\slmgr.vbs /ipk NPPR9-FWDCX-D2C8J-H872K-2YT43
cscript //nologo c:\windows\system32\slmgr.vbs /skms kms.03k.org
cscript //nologo c:\windows\system32\slmgr.vbs /ato
cscript //nologo c:\windows\system32\slmgr.vbs /skms zhang.yt
echo Disable automatic BitLocker encryption
reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
echo Disable UAC
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
echo Fix Camera
reg add "HKLM\SOFTWARE\Microsoft\Windows Media Foundation\Platform" /v EnableFrameServerMode /t REG_DWORD /d 0 /f
echo Install frameworks
powershell -command "& {Add-AppxPackage -Path .\WOA\Dependencies\*.AppxBundle}"
powershell -command "& {Add-AppxPackage -Path .\WOA\Dependencies\*.Appx}"
powershell -command "& {Add-AppxPackage -Path .\WOA\Apps\*.AppxBundle}"
powershell -command "& {Add-AppxPackage -Path .\WOA\Apps\*.Appx}"
pause
goto :eof

::Install Extra packages
:MAIN_MENU_OPTION_7
echo Install Internet Explorer 11
dism /Online /Add-Package /PackagePath:.\Extra\microsoft-windows-internetexplorer-optional-package.cab
echo Install Windows 10 App updates
powershell -command "& {Add-AppxPackage -Path .\Extra\Dependencies\*.AppxBundle}"
powershell -command "& {Add-AppxPackage -Path .\Extra\Dependencies\*.Appx}"
powershell -command "& {Add-AppxPackage -Path .\Extra\Apps\*.AppxBundle}"
powershell -command "& {Add-AppxPackage -Path .\Extra\Apps\*.Appx}"
echo Install Office RT 2013
.\Extra\Office\setup.exe
echo Install Office license
cscript //nologo c:\windows\system32\slmgr.vbs /upk //b ebef9f05-5273-404a-9253-c5e252f50555
for %%g in (.\Extra\*.xrm-ms) do (
	cscript //nologo c:\windows\system32\slmgr.vbs //b /ilc %%~nxg
	)
cscript //nologo c:\windows\system32\slmgr.vbs /ipk KBKQT-2NMXY-JJWGP-M62JB-92CD4
echo Install NVIDIA Serial 16550 UART Driver
pnputil /add-driver .\Extra\Uart16550tegra.inf /install
echo Install Microsoft Print To PDF
pnputil /add-driver "C:\Windows\System32\spool\tools\Microsoft Print To PDF\prnms009.inf" /install
echo Install Microsoft XPS Document Writer
pnputil /add-driver "C:\Windows\System32\spool\tools\Microsoft XPS Document Writer\prnms001.inf" /install
pause
goto :eof

:MAIN_MENU_OPTION_DEFAULT
echo Unknown option.
goto :eof
:MAIN_MENU_OPTION_END
goto :eof

:show_main_menu
echo 0. Install original Windows RT
echo 1. Disable UAC
echo 2. Install Secure Boot Debug Policy
echo 3. Disable Secure Boot
echo 4. Install Windows 10
echo 5. Bypass Windows 10 OOBE error
echo 6. Set up Windows 10
echo 7. Install Extra packages
goto :eof

:exit
pause
exit
goto :eof

:reboot
pause
shutdown /r /t 0
goto :eof

:dism
if "%~2" == "" (set DISM_DIR=c) else (set DISM_DIR=%2)
dism /apply-image /imagefile:%1 /applydir:%DISM_DIR%: /index:1
goto :eof

:diskpart
call :create_diskpart_script_%1 diskpart_%1.txt
diskpart /s diskpart_%1.txt
del diskpart_%1.txt
goto :eof

:create_diskpart_script_clean
echo select disk 0 > %1
echo clean >> %1
echo exit >> %1
goto :eof

:create_diskpart_script_format
echo select disk 0 > %1
type .\sources\CreatePartitions-UEFI.txt >> %1
goto :eof

:create_diskpart_script_mount
echo select disk 0 > %1
echo select partition 2 >> %1
echo assign letter=s >> %1
echo exit >> %1
goto :eof

:create_diskpart_script_win10
echo select disk 0 > %1
echo clean >> %1
echo convert gpt >> %1
echo create partition efi size=36 >> %1
echo format quick fs=fat32 >> %1
echo assign letter=s >> %1
echo create partition primary >> %1
echo format quick compress fs=ntfs >> %1
echo gpt attributes=0x0000000000000000 >> %1
echo assign letter=c >> %1
echo exit >> %1
goto :eof

:eof