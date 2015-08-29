# Gigabyte-GA-Z77X DSDT Patch

Support files for Gigabyte GA-Z77X motherboards running OS X 10.9+.

These support files can help you configure the post-installation process on Gigabyte GA-Z77X motherboards. The current repository uses a custom SSDT (customized for each motherboard) as well as config.plist edits to patch everything on the fly regardless of differing BIOS versions. Manual DSDT edits are no longer needed and are no longer included in this repo.

### Usage
[![asciicast](https://asciinema.org/a/0xufcqxd6jm3qwo1ss0asegd6.png)](https://asciinema.org/a/0xufcqxd6jm3qwo1ss0asegd6)
Please refer [to the wiki](https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch/wiki) for more information as well as detailed instructions.

### Supported Motherboards
Currently, the following motherboards are supported by the GA-Z77X script and the custom SSDTs in the repo:
- GA-Z77X-D3H
- GA-Z77X-UD3H (-WB WIFI)
- GA-Z77X-UD5H (-WB WIFI)
- GA-Z77X-UP5 TH
- GA-Z77X-UP7

### Changelog
Version 1.7.5 (2015-08-28)
- Updated Mieze's IntelMausiEthernet driver
- Updated Clover to r3262
- Replaced AppleUSBEHCIPortInjector.kext & AppleUSBXHCIPortInjector.kext with GA-Z77X_USBPortInjector.kext
- Added FreqVectorInjector.kext to suppress `X86PlatformShim::start - Failed to send stepper` errors in kernel logs

Version 1.7.4 (2015-08-24)
- Refined motherboard detection (uses OEMBoard property injected by Clover in `IODeviceTree` instead of `bdmesg`)
- Added AppleUSBXHCIPortInjector.kext creation for OS X 10.11 (experimental)
- Fixed GA-Z77X-UP5 TH & GA-Z77X-UP7 motherboard detection
- Slight code refactoring

Version 1.7.3 (2015-08-23)
- Added Clover DSDT patches to generic config to make SSDTs smaller

Version 1.7.2 (2015-08-22)
- Fixed more bugs reported by sreda2013 (thanks again for your patience)
- Fixed more typos in the script
- Added AppleUSBEHCIPortInjector.kext creation for OS X 10.11

Version 1.7.1 (2015-08-19)
- Fixed more bugs related to kext installation & iasl (thanks to sreda2013 again for reporting them)
- Fixed more typos in the script

Version 1.7 (2015-08-18)
- Fixed motherboard detection bugs (thanks to sreda2013 for reporting them)
- Added styling to main script
- Added detection of other UEFI bootloaders on the ESP
- Fixed bugs related to simpleMacSerial & simpleMLB
- Fixed typos in script

Version 1.5 (2015-08-17)
- Near-complete rewrite of the GA-Z77X.sh script
- Reworked repository to use custom SSDTs
- Removed DSDT patches
- Improved El Capitan support
- Updated Clover to r3259
- Updated HFSPlus.efi (extracted from MacBookPro11,4 firmware)
- Added support for more motherboards: GA-Z77X-D3H, GA-Z77X-UD3H, GA-Z77X-UP7
- Added support for PS/2 using RehabMan's VoodooPS2Controller
- Added support for rev 1.0 motherboards using the Atheros AR8151 v2.0 NIC using Shailua's AtherosL1cEthernet
- Added support for motherboards using using Realtek NICs using RehabMan's fork of Mieze's RealtekRTL8111
- Updated Mieze's AtherosE2200Ethernet & IntelMausiEthernet drivers

2015-07-18
- Removed GA-Z77X-D3H support (temporarily)
- Added GA-Z77X-UP5 TH support
- Updated script to use OEM SSDTs instead of generating them
- Updated script to add El Capitan support


### Issue Reporting
If you run into an issue while running the GA-Z77X.sh post-installation script or have an issue with the custom SSDTs, please report it on [GitHub Issues](https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch/issues).

### Credits
Special thanks to Mieze, Piker-Alpha, PJALM, RampageDev, RehabMan, Shailua, SJ_Underwater, the-darkvoid, and toleda for their original works; this would not have been possible if not for their work.
Also, special thanks to [AustinSMU](https://github.com/AustinSMU); the repo design and large parts of the script were based off his [PRECISION-M3800-OSX repo](https://github.com/AustinSMU/PRECISION-M3800-OSX). 
