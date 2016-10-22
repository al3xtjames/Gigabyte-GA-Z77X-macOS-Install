# Gigabyte GA-Z77X DSDT Patch

Support files for running macOS 10.11+ on Gigabyte 7 Series motherboards.

This is a WIP branch for macOS Sierra. Support for other boards will be re-added soon.

These support files can help you configure the post-installation process on Gigabyte 7 Series motherboards. The current repository uses custom SSDTs for each motherboard along with the GA-Z77X.sh post-installation script to create a working macOS installation.

### Usage

```
git clone --recursive https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch --branch sierra
```
```
cd Gigabyte-GA-Z77X-DSDT-Patch
```
```
./GA-Z77X.sh --install
```

### Supported Motherboards
Currently, the following motherboards are supported by the GA-Z77X.sh script:
 - GA-Z77X-UD5H (-WB WIFI)
 - GA-Z77X-UP5 TH

### Issue Reporting
If you run into an issue while running the GA-Z77X.sh post-installation script or have an issue with the custom SSDTs, please report it on [GitHub Issues](https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch/issues).

### Credits
Thanks to:
 - [Mieze](https://github.com/Mieze) - [AtherosE2200Ethernet](https://github.com/Mieze/AtherosE2200Ethernet), [IntelMausiEthernet](https://github.com/Mieze/IntelMausiEthernet)
 - [netkas](http://netkas.org/) & [kozlek](https://github.com/kozlek) - [FakeSMC/HWSensors](https://github.com/RehabMan/OS-X-FakeSMC-kozlek)
 - [Pike R. Alpha](https://github.com/Piker-Alpha) - [ACPI table examples](https://github.com/Piker-Alpha/DSDT)
 - [RehabMan](https://github.com/RehabMan) - [Example SSDTs](https://github.com/RehabMan/OS-X-Clover-Laptop-Config)
 - [Shailua](http://www.insanelymac.com/forum/user/933246-shailua/) - [AtherosL1cEthernet](http://www.insanelymac.com/forum/topic/283086-updated-atheros-ar8131325152-driver-for-107108/)
 - [the-darkvoid](https://github.com/the-darkvoid) - [XPS9530-OSX Repo/Script](https://github.com/the-darkvoid/XPS9530-OSX)
 - [vit9696](https://github.com/vit9696) - [AppleALC](https://github.com/vit9696/AppleALC) & [Shiki](https://github.com/vit9696/Shiki)
