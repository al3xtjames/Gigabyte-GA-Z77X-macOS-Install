#!/bin/bash
#
# GA-Z77X OS X Post Installation Script
# Supports various Gigabyte GA-Z77X motherboards
# Gigabyte GA-Z77X DSDT Patch Repo - http://git.io/vIatr

# Initialize global variables

## The script version
gScriptVersion="1.5"

## The user ID
gID=$(id -u)

## The motherboard, will be properly initialized later
gMotherboard="Unknown"

## The folder containing the repo
gRepo=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## The SMBIOS product name
gProductName="iMac13,2"

## The location where the EFI partition is mounted
gEFIMount="Unknown"

#-------------------------------------------------------------------------------#
function _identifyMotherboard()
{
	# Initialize variables
	motherboard=$(tools/bdmesg | grep "Z77X" | cut -d '-' -f2 | strings)

	# Identify the motherboard
	case $motherboard in
		'D3H')
			gMotherboard="D3H";;
		'UD3H')
			gMotherboard="UD3H";;
		'UD5H')
			gMotherboard="UD5H";;
		'UP5 TH')
			gMotherboard="UP5-TH";;
		'UP7')
			gMotherboard="UP5-TH";;
		*)
			echo "ERROR: "$motherboard" motherboard is unsupported by this script. Exiting..." && exit 1;;
	esac
}

function _download()
{
	# Initialize variables
	url="$1"
	remoteName="$2"
	fileName="$3"

	# Download the file
	echo "Downloading $remoteName..."
	curl --output "$fileName" --progress-bar --location "$url"
}

function _checkRoot()
{
	if [ $gID -ne 0 ]; then
		# Re-run the script as root
		echo "This part of the script needs to be run as root."
		sudo printf ""
	fi
}

function _installKextEFI()
{
	# Initialize variables
	kext="$1"

	# Copy the kext to the Clover kexts folder on the EFI partition
	cp -R "$kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
}

function _detectAtherosNIC()
{
	# Gigabyte shipped different revisions of boards with different Atheros NICs
	# AtherosL1cEthernet supports AR8151, while AtherosE2200Ethernet supports AR8161

	# Initialize variables
	atherosNIC=$("$gRepo/tools/dspci" | grep "Ethernet controller" | grep "1969" | cut -d ':' -f 4 | cut -d ']' -f 1)

	# Gigabyte shipped different revisions of boards with different Atheros NICs
	# AtherosL1cEthernet supports AR8151, while AtherosE2200Ethernet supports AR8161
	# Install the correct Atheros kext if an Atheros NIC is detected
	if [[ ! -z $atherosNIC ]]; then
		case $atherosNIC in
			1083) # Atheros AR8151 v2.0 GbE - use AtherosL1cEthernet
				printf "Detected Atheros AR8151 v2.0 NIC [1969:1083], installing AtherosL1cEthernet.kext..."
				_installKextEFI "$gRepo/kexts/AtherosL1cEthernet.kext"
				echo "complete";;
			1091) # Atheros AR8161 GbE - use AtherosE2200Ethernet
				printf "Detected Atheros AR8161 NIC [1969:1091], installing AtherosE2200Ethernet.kext..."
				_installKextEFI "$gRepo/kexts/AtherosE2200Ethernet.kext"
				echo "complete";;
		esac
	fi
}

function _detectIntelNIC()
{
	# Initialize variables
	intelNIC=$("$gRepo/tools/dspci" | grep "Ethernet controller" | grep "8086" | cut -d ':' -f 4 | cut -d ']' -f 1)

	# Install IntelMausiEthernet.kext if an Intel NIC is detected
	if [[ ! -z $intelNIC ]]; then
		case $intelNIC in
			1503) # Intel 82579V GbE
				printf "Detected Intel 82579V NIC [8086:1503], installing IntelMausiEthernet.kext..."
				_installKextEFI "$gRepo/kexts/IntelMausiEthernet.kext"
				echo "complete";;
		esac
	fi
}

function _detectRealtekNIC()
{
	# Initialize variables
	realtekNIC=$("$gRepo/tools/dspci" | grep "Ethernet controller" | grep "10ec" | cut -d ':' -f 4 | cut -d ']' -f 1)
	
	# Install RealtekRTL8111.kext if a Realtek NIC is detected
	if [[ ! -z $realtekNIC ]]; then
		case $realtekNIC in
			8168) # Realtek RTL8168/RTL8111 GbE
				printf "Detected Realtek RTL8168/RTL8111 NIC [10ec:8168], installing RealtekRTL8111.kext..."
				_installKextEFI "$gRepo/kexts/RealtekRTL8111.kext"
				echo "complete";;
		esac
	fi
}

function _detectMarvellSATA()
{
	# Initialize variables
	marvellSATA=$("$gRepo/tools/dspci" | grep "SATA controller" | grep "1b4b")

	# Install AHCI_3rdParty_SATA if Marvell SATA controllers are detected
	if [[ ! -z $marvellSATA ]]; then
		printf "Detected Marvell SATA controller, installing AHCI_3rdParty_SATA.kext..."
		_installKextEFI "$gRepo/kexts/AHCI_3rdParty_SATA.kext"
		echo "complete."
	fi
}

function _detectXHCI()
{
	# Initialize variables
	plist="$gEFIMount/EFI/CLOVER/config.plist"
	xhciList=$("$gRepo/tools/dspci" | grep "xHCI Host Controller\|USB 3.0 Host Controller")
	nonIntelXHCI=$(echo $xhciList | grep -Fv "Intel")

	# Add the kext patches to the plist if non-Intel XHCI controllers are detected
	if [[ ! -z $nonIntelXHCI ]]; then
		/usr/libexec/PlistBuddy -c "Merge $gRepo/patches/AppleUSBXHCI.plist ':KernelAndKextPatches:KextsToPatch'" $plist
	fi
}

function _detectPS2()
{
	case $gMotherboard in
		"D3H" | "UD3H" | "UP7") # Motherboards that have a PS/2 port
			echo "Detected motherboard with PS/2 port, installing VoodooPS2Controller..."
			_installKextEFI "$gRepo/kexts/VoodooPS2Controller.kext"
			cp org.rehabman.voodoo.driver.Daemon.plist /Library/LaunchDaemons
			cp VoodooPS2Controller /usr/bin
			echo "complete";;
	esac	
}

function _genSMBIOSData()
{
	# Initialize variables
	printf "Generating SMBIOS data..."
	plist="$gEFIMount/EFI/CLOVER/config.plist"
	serialNumber=$(externals/simpleMacSerial.sh/simpleMacSerial.sh iMac13,2)
	MLB=$(externals/simpleMLB.sh/simpleMLB.sh $serialNumber)
	SmUUID=$(uuidgen)
	echo "complete."

	# Copy the generated data to the plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:ProductName '$gProductName'" $plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" $plist
	/usr/libexec/plistbuddy -c "Set :RtVariables:MLB '$MLB'" $plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SmUUID '$SmUUID'" $plist
}
#-------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------#
function _gitUpdate()
{
	# Make sure we're in the repo folder
	cd "$gRepo"

	# Update the repo files
	echo "Updating local data to latest version"
	echo "Updating to latest Gigabyte-GA-Z77X-DSDT-Patch git master"
	git pull

	# Update the external repos
	echo "Initializing external repos"
	git submodule update --init --recursive
	echo "Updating external repos"
	git submodule foreach git pull origin master
}

function _installSSDT()
{
	clear

	# Initialize variables
	url="https://raw.githubusercontent.com/theracermaster/DSDT/master/SSDT-GA-Z77X-$gMotherboard.dsl"

	# Download the file
	_download $url "SSDT-GA-Z77X-$gMotherboard.dsl" /tmp/SSDT.dsl

	# Compile the SSDT and move it to the right directory
	iasl /tmp/SSDT.dsl
	mv "/tmp/SSDT-GA-Z77X-$gMotherboard.aml" "$gRepo/EFI/CLOVER/ACPI/patched/SSDT.aml"
}

function _injectHDA()
{
	# Initialize variables
	plist="$gRepo/EFI/CLOVER/config.plist"

	# Load AppleHDA.kext so we can ID the codec
	sudo kextload "/System/Library/Extensions/AppleHDA.kext"

	# Run the HDA injector script
	sudo "$gRepo/externals/hdaInjector.sh/hdaInjector.sh"

	# Copy config.plist and add the kext patches to it
	cp "$gRepo/config-generic.plist" "$plist"
	/usr/libexec/PlistBuddy -c "Merge /tmp/ktp.plist ':KernelAndKextPatches:KextsToPatch'" $plist
}

function _installClover()
{
	clear

	# Find the BSD device name for the current OS disk
	osVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)

	# Find the EFI partition of the disk
	efiVolume=$(diskutil list "$osVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')

	# Check if the EFI partition is already mounted; if not, mount it
	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) mounted at $mountPoint."
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) is already mounted at $mountPoint."
	fi
	gEFIMount="$mountPoint"

	# Check if there is an existing bootloader install; if so, ask the user if it can be overwritten
	if [ -d "$gEFIMount/EFI" ]; then
		printf "An existing UEFI bootloader is present. Do you want to overwrite it (y/n)? "
		read choice
		case "$choice" in
			y|Y)
				echo "Removing directory..."
				rm -rf "$gEFIMount/EFI";;
			n|N)
				echo "Renaming directory..."
				mv "$gEFIMount/EFI" "$gEFIMount/EFIbackup";;
		esac
	fi

	# Copy the directories to the EFI partition & create the kext directory
	echo "Installing Clover to $gEFIMount..."
	cp -R "$gRepo/EFI" "$gEFIMount"
	mkdir -p "$gEFIMount/EFI/CLOVER/kexts/Other"

	# Install FakeSMC
	_installKextEFI "$gRepo/kexts/FakeSMC.kext"

	# Check what other kexts/patches are needed and install them
	_detectAtherosNIC
	_detectIntelNIC
	_detectRealtekNIC
	_detectMarvellSATA
	_detectXHCI
	_detectPS2

	# Generate the SMBIOS data
	_genSMBIOSData

	# Rebuld kext caches
	printf "Rebuilding kext caches..."
	sudo touch /System/Library/Extensions
	echo "complete." && echo

	# We're done here, let's prompt the user to reboot
	echo "Installation complete. You must reboot in order for the changes to apply."
	printf "Do you want to reboot now (y/n)? "
	read choice
	case "$choice" in
		y|Y)
			echo "Rebooting..."
			sudo reboot;;
		*)
			exit 0;;
	esac
}

function _cleanup()
{
	# Make sure we're in the repo folder
	cd "$gRepo"

	# Delete the generated files
	printf "Deleting generated files in repo folders..."
	rm -f EFI/CLOVER/ACPI/patched/*.aml
	rm -f EFI/CLOVER/config.plist
	rm -f /tmp/*.aml
	rm -f /tmp/*.dsl
	sudo rm -rf /tmp/*.plist
	echo "complete."
}
#-------------------------------------------------------------------------------#

RETVAL=0

case "$1" in
	--update)
		_gitUpdate
		RETVAL=1;;
	--install-ssdt)
		_identifyMotherboard
		_installSSDT
		RETVAL=1;;
	--inject-hda)
		_checkRoot
		_injectHDA
		RETVAL=1;;
	--install-clover)
		_checkRoot
		_installClover
		RETVAL=1;;
	--cleanup)
		_checkRoot
		_cleanup
		RETVAL=1;;
	*)
		echo "GA-Z77X.sh OS X Post-Installation Script"
		echo "Supports various Gigabye GA-Z77X motherboards"
		echo
		echo "Usage: ./GA-Z77X.sh <command>, where <command> is one of the following:"
		echo
		echo "     --update             Update the repo & helper files to the latest version"
		echo "     --install-ssdt       Install the SSDT for your motherboard"
		echo "     --inject-hda         Install injector kext for your audio codec"
		echo "     --install-clover     Install Clover to your EFI partition"
		echo "     --cleanup            Delete files generated by this script in repo folders"
		echo
		echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
esac

exit $RETVAL
