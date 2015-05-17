# Gigabyte-GA-Z77X-UD5H DSDT Patches

DSDT Patches for the Gigabyte GA-Z77X-UD5H motherboard for running OS X.

## Using These Patches
These patches can be applied to a cleanly-extracted native DSDT from the Gigabyte GA-Z77X-UD5H motherboard using an editor such as [MaciASL](http://maciasl.sourceforge.net). Add https://raw.githubusercontent.com/theracermaster/Gigabyte-GA-Z77X-UD5H-DSDT-Patch/master as a repo in MaciASL > Preferences > Sources.
![MaciASL Preferences Screenshot](http://i.imgur.com/fV48uhM.png)

Special thanks to PJALM, toleda, and RampageDev for their original edits; this would not have been possible if not for their work.

## Post-Installation
To get everything on this board working in OS X, several kexts/drivers/etc. are required:

- [FakeSMC+HWSensors (RehabMan fork)](https://bitbucket.org/RehabMan/os-x-fakesmc-kozlek) - OS X driver for emulating SMC device and monitoring various hardware sensors
- [cloverALC](https://github.com/toleda/audio_CloverALC) - OS X driver for onboard Realtek ALC898 Audio Controller
- [IntelMausiEthernet](http://www.insanelymac.com/forum/topic/304235-intelmausiethernetkext-for-intel-onboard-lan/) - OS X driver for onboard Intel 82579V Gigabit Ethernet Controller
- [AtherosE2200Ethernet](http://www.insanelymac.com/forum/topic/300056-solution-for-qualcomm-atheros-ar816x-ar817x-and-killer-e220x) - OS X driver for onboard Qualcomm Atheros AR8161 Gigabit Ethernet Controller
- [MarvellAHCIPortInjector](https://github.com/theracermaster/MarvellAHCIPortInjector) - OS X driver for injecting Marvell 88SE9172 into AppleAHCIPort (shows in System Information)
- [ssdtPRGen.sh](https://github.com/Piker-Alpha/ssdtPRGen.sh) - Generates SSDT for your CPU (make sure you use the argument `-w 3` on Yosemite) to enable OS X power management (requires proper SMBIOS entry)

### Clover Bootloader Configuration
#### config.plist
Since the [Clover wiki](http://clover-wiki.zetam.org/Home) exists, I will only post what's mandatory in Clover's config.plist, not everything.

##### ACPI:
```plist
<key>DSDT</key>
<dict>
	<key>Name</key>
	<string>DSDT.aml</string>
</dict>
```
Since we are using an already-patched DSDT, we don't need any of Clover's DSDT patching.
```plist
<key>SSDT</key>
<dict>
	<key>DropOem</key>
	<true/>
	<key>Generate</key>
	<false/>
</dict>
```
We are also using a custom SSDT generated with `./ssdtPRGen -w 3`, so we need to drop the OEM SSDT tables and disable Clover's SSDT generation features.
##### Boot:
```plist
<key>Arguments</key>
<string>kext-dev-mode=1</string>
```
All the custom kexts we are using (FakeSMC, cloverALC, IntelMausiEthernet, AtherosE2200Ethernet, MarvellAHCIPortInjector) are unsigned, so we need to enable this, or else we cannot boot.

##### Devices > Audio:
```plist
<key>AFGLowPowerState</key>
<false/>
```
Helps eliminate some popping caused by the audio controller going to sleep. Doesn't always prevent it, so you might want to use [antipop](http://www.tomsick.net/projects/antipop.html).
```plist
<key>ResetHDA</key>
<true/>
```
Needed to prevent audio from breaking after sleep.
##### Devices > USB:
```plist
<key>FixOwnership</key>
<false/>
<key>Inject</key>
<false/>
```
Neither of these options are necessary, since we edited the USB devices in our DSDT
##### Graphics > Inject:
```plist
<key>ATI</key>
<false/>
<key>Intel</key>
<false/>
<key>NVidia</key>
<false/>
```
Clover graphics injection should be disabled. Use a [graphics DSDT patch](https://github.com/theracermaster/Gigabyte-GA-Z77X-UD5H-DSDT-Patch/tree/master/Graphics) instead.
##### KernelAndKextPatches > KextsToPatch
cloverALC will add two entries here for AppleHDA patching. You shouldn't have to add any other entries for audio.
```plist
<key>Comment</key>
<string>TRIM Enabler Patch</string>
<key>Find</key>
<data>QVBQTEUgU1NEAA==</data>
<key>Name</key>
<string>IOAHCIBlockStorage</string>
<key>Replace</key>
<data>AAAAAAAAAAAAAA==</data>
```
This is a useful patch that enables TRIM on non-Apple SSDs. Since it's a Clover kext patch, it's applied automatically at every boot, so no need to manually patch the kext.

If you need a [modified AMD framebuffer personality](https://github.com/theracermaster/Gigabyte-GA-Z77X-UD5H-DSDT-Patch/tree/master/Graphics#editing-amd-framebuffer-personalities), you can insert the patch here as well.
##### RtVariables
```plist
<key>MLB</key>
<string>XXXXXXXXXXXXX</string>
```
You can generate a MLB using my [simpleMLB script](https://gist.github.com/theracermaster/b6a9db46b14061d4c995). Please read the comments in the script before using it.
```plist
<key>ROM</key>
<string>UseMacAddr0</string>
```
The ROM value should be set to the MAC address of your first NIC (don't generate one).
##### SMBIOS
Use Clover Configurator to generate a valid SMBIOS for Clover. I recommend using either iMac13,2 or Macmini6,2. Make sure the serial number is generated properly (should not be a real serial, you can check [here](https://selfsolve.apple.com/agreementWarrantyDynamic.do) if it's valid or not). You also need a SmUUID value, which you can generate using `uuidgen`.
##### SystemParameters
```plist
<key>InjectKexts</key>
<true/>
<key>InjectSystemID</key>
<true/>
```
These two values should always be set to true.
