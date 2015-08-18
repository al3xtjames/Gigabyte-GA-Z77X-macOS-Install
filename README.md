# Gigabyte-GA-Z77X DSDT Patch

Support files for Gigabyte GA-Z77X motherboards running OS X.

These support files can help you configure the post-installation process on Gigabyte GA-Z77X motherboards. The current repository uses a custom SSDT (customized for each motherboard) as well as config.plist edits to patch everything on the fly regardless of differing BIOS versions. Manual DSDT edits are no longer needed and are no longer included in this repo.

### Usage
[![asciicast](https://asciinema.org/a/7jwa4v0gfoalxmwkqhg70cqqe.png)](https://asciinema.org/a/7jwa4v0gfoalxmwkqhg70cqqe)
Please refer [to the wiki](https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch/wiki) for more information as well as detailed instructions.

### Supported Motherboards
Currently, the following motherboards are supported by the GA-Z77X script and the custom SSDTs in the repo:
- GA-Z77X-D3H
- GA-Z77X-UD3H
- GA-Z77X-UD5H
- GA-Z77X-UP5 TH
- GA-Z77X-UP7

### Changelog
2015-08-18
- Fix motherboard detection bugs (thanks to sreda2013 for reporting them)
- Added styling to main script
- Added detection of other UEFI bootloaders on the ESP

2015-08-17
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
