# ssdtGen 0.0.1beta

Introduction

ssdtGen is an automated bash script that attempts to build and compile SSDTs for X99 systems running Mac OS.

You can download the latest version of iMessageTool to your Desktop by entering the following command in a terminal window:
```
curl -o ~/Desktop/ssdtGen.sh https://github.com/mattcarlotta/ssdtGen/blob/master/ssdtGen.sh
```
You can then verify the downloaded size (should be about 25kb):
```
wc -c ~/Desktop/ssdtGen.sh
```
You must change the file permissions to make it executable:
```
chmod +x ~/Desktop/ssdtGen.sh
```
Lastly, use this command to run the script:
```
~/Desktop/ssdtGen.sh
```

--------------------------------------------------------------------------------------------------------------

**Special notes:
- DSDT ACPI tables must be vanilla(1). If any devices are renamed, forget it about it. Won't work.
(1) XHCI must be named XHC via config.plist DSDT patch (recommended to install USBInjectAll.kext + XHCI-x99-injector.kext with a custom SSDT-UAIC.aml):
```
Comment: Change XHCI to XHC
Find: 58484349
Replace: 5848435f

Comment: Change XHC1 to XHC
Find: 58484331
Replace: 5848435F

```

**Note: This script is highly experimental! Use any generated SSDTs with caution.
