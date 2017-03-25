# ssdtGen 0.0.1beta

Introduction

ssdtGen is an automated bash script that attempts to build and compile SSDTs for X99 systems running Mac OS.

You can download the latest version of ssdtGen to your Desktop by entering the following command in a terminal window:
```
cd ~/Desktop
curl -O -L https://raw.githubusercontent.com/mattcarlotta/ssdtGen/master/ssdtGen.sh
```
You can then verify the downloaded size (should be about 29kb):
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
DSDT ACPI tables must be vanilla(1). If any devices are renamed, forget it about it. Won't work.

1.) XHCI must be named XHC via config.plist DSDT patch (recommended to install USBInjectAll.kext + XHCI-x99-injector.kext with a custom SSDT-UAIC.aml):
- <a href="https://www.tonymacx86.com/threads/guide-creating-a-custom-ssdt-for-usbinjectall-kext.211311/">Rehabman's Guide for Creating a Custom SSDT for USBInjectAll.kext</a>
- <a href="http://www.insanelymac.com/forum/topic/313296-guide-mac-osx-1012-with-x99-broadwell-e-family-and-haswell-e-family/page-53#entry2354822"> My Guide for using UsbInjectAll.kext with a Custom SSDT-UIAC.aml</a>

**Note: This script is highly experimental! Use any generated SSDTs with caution.
