# ssdtGen 0.1.4beta

Introduction

ssdtGen is an automated bash script that attempts to build and compile SSDTs for X99/Z170 systems running Mac OS. Specifically, it will inject properties into your ACPI tables for: on-board sound, an external GPU/HDMI audio, sSata Contoller, ethernet, IMEI controller, LPC support, NVMe devices, Sata Controller, SBUS controller, XHC usb power options, and XOSI support.

Please note that some of the devices will still need "drivers" (kexts) to be fully functional:
* <a href="http://www.insanelymac.com/forum/files/file/436-ahciportinjectorkext/">AHCIPortInjector.kext</a> for HDD/SSD devices (EVSS and SAT0/SAT1)
* <a href="http://www.insanelymac.com/forum/topic/304235-intelmausiethernetkext-for-intel-onboard-lan/#entry2107186">IntelMausiEthernet.kext</a> for ethernet (GLAN)
* Custom AppleHDA-ALCXXXX.kext OR <a href="http://www.insanelymac.com/forum/topic/311293-applealc-%E2%80%94-dynamic-applehda-patching/#entry2221652">AppleALC.kext</a> + <a href="https://bitbucket.org/RehabMan/os-x-eapd-codec-commander">CodecCommander.kext</a> OR <a href="http://www.insanelymac.com/forum/topic/308387-el-capitan-realtek-alc-applehda-audio/#entry2172944">RealtekALC.kext</a> for on-board and HDMI/DP sound (HDAU and HDEF)
* <a href="http://www.insanelymac.com/forum/topic/312525-nvidia-web-driver-updates-for-macos-sierra-update-03272017/">Nvidia Web Drivers</a> for GPU recognition

You can download the latest version of ssdtGen to your Desktop by entering the following commands in a terminal window:
```
cd ~/Desktop && curl -O -L https://raw.githubusercontent.com/mattcarlotta/ssdtGen/master/ssdtGen.sh
```
You can then verify the downloaded size (should be about 57kb):
```
wc -c ssdtGen.sh
```
You must change the file permissions to make it executable:
```
chmod +x ssdtGen.sh
```
Lastly, use this command to run the script:
```
~/Desktop/ssdtGen.sh
```

Commands:
```
buildall (will attempt to build all SSDTs -- except SSDT-NVME)
build NAME (will attempt to build a single SSDT -- see help for SSDT build names and their functionality)
debug (will run the script while generating a debug_output.txt file)
help (will display help instructions)
exit (will exit the script)
```

Go here for more support: <a href="http://www.insanelymac.com/forum/topic/322811-ssdtgen-script-for-custom-generated-ssdts-x99z170-systems/#entry2403977">ssdtGen script for custom generated SSDTs (x99/z170 systems)</a>

--------------------------------------------------------------------------------------------------------------

**Limitation Notes

* DSDT ACPI tables must be vanilla(†). If any devices are renamed, forget about it. Won't work.
* This script will install IASL to the usr/local/bin directory if it's missing from usr/bin or usr/local/bin
* Piker-Alpha's <a href="https://github.com/Piker-Alpha/ssdtPRGen.sh">ssdtPRgen</a> is still required if you wish to have CPU power management
* This script currently only supports 1 connected (external) GPU. If you have or are using the IGPU (Intel's
internal GPU located on the CPU die), then GPU injection won't work. Also, if you have multiple external
GPU's attached, only the first one will be injected.
* A generated SSDT-NVME.aml requires a spoofed HackrNVMeFamily-10_xx_x.kext to be loaded††
* If a SSDT-xxxx.aml fails to compile, then it won't be saved. Check the terminal output for errors.

† If you're using a custom DSDT.aml, it may conflict with the SSDTs if it already has DSMs injected at the device. Also, XHCI must be named XHC via config.plist DSDT patch (recommended to install USBInjectAll.kext + XHCI-x99-injector.kext with a custom SSDT-UAIC.aml):
- <a href="https://www.tonymacx86.com/threads/guide-creating-a-custom-ssdt-for-usbinjectall-kext.211311/">Rehabman's Guide for Creating a Custom SSDT for USBInjectAll.kext</a>
- <a href="http://www.insanelymac.com/forum/topic/313296-guide-mac-osx-1012-with-x99-broadwell-e-family-and-haswell-e-family/page-53#entry2354822"> My Guide for using UsbInjectAll.kext with a Custom SSDT-UIAC.aml</a>

†† In order to generate a spoofed HackrNVMeFamily-10_xx_x.kext to work with SSDT-NVME.aml, please follow:
* <a href="https://www.tonymacx86.com/threads/guide-hackrnvmefamily-co-existence-with-ionvmefamily-using-class-code-spoof.210316/">HackrNVMeFamily co-existence with IONVMeFamily using class-code spoof<a/>
* <a href="http://www.insanelymac.com/forum/topic/312803-patch-for-using-nvme-under-macos-sierra-is-ready/page-37#entry2343228">Generic HackrNVMeFamily guide<a/> (skip steps 9-11, as this script will generate one for you)

**Note: This script is in beta testing. Therefore, expect some bugs/issues to occur.
