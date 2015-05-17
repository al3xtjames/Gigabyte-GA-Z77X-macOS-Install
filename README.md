# Gigabyte-GA-Z77X-UD5H DSDT Patches

DSDT Patches for the Gigabyte GA-Z77X-UD5H motherboard for running OS X.

## Using These Patches
These patches can be applied to a cleanly-extracted native DSDT from the Gigabyte GA-Z77X-UD5H motherboard using an editor such as [MaciASL](http://maciasl.sourceforge.net). Add https://raw.githubusercontent.com/theracermaster/Gigabyte-GA-Z77X-UD5H-DSDT-Patch/master as a repo in MaciASL > Preferences > Sources.
![MaciASL Preferences Screenshot](http://i.imgur.com/fV48uhM.png)

Special thanks to PJALM, toleda, and RampageDev for their original edits; this would not have been possible if not for their work.

## Post-Installation
To get everything on this board working in OS X, several post-installation steps/kexts/drivers/etc. are required:

- [FakeSMC+HWSensors (RehabMan fork)](https://bitbucket.org/RehabMan/os-x-fakesmc-kozlek) - OS X driver for emulating SMC device and monitoring various hardware sensors
- [cloverALC](https://github.com/toleda/audio_CloverALC) - OS X driver for onboard Realtek ALC898 Audio Controller
- [IntelMausiEthernet](http://www.insanelymac.com/forum/topic/304235-intelmausiethernetkext-for-intel-onboard-lan/) - OS X driver for onboard Intel 82579V Gigabit Ethernet Controller
- [AtherosE2200Ethernet](http://www.insanelymac.com/forum/topic/300056-solution-for-qualcomm-atheros-ar816x-ar817x-and-killer-e220x) - OS X driver for onboard Qualcomm Atheros AR8161 Gigabit Ethernet Controller
- [MarvellAHCIPortInjector](https://github.com/theracermaster/MarvellAHCIPortInjector) - OS X driver for injecting Marvell 88SE9172 into AppleAHCIPort (shows in System Information)
- [ssdtPRGen.sh](https://github.com/Piker-Alpha/ssdtPRGen.sh) - Generates SSDT for your CPU (make sure you use the argument `-w 3` on Yosemite) to enable OS X power management (requires proper SMBIOS entry)
