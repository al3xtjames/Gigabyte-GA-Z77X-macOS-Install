#!/bin/bash
# Gigabyte GA-Z77X OS X Post-Install Script by theracermaster
# Supports various Gigabyte GA-Z77X motherboards
# Gigabyte GA-Z77X DSDT Patch Repo - http://git.io/vIatr

# Initialize global variables

## The script version
gScriptVersion="1.8.3"

## The user ID
gID=$(id -u)

## The motherboard, will be properly initialized later
gMotherboard="Unknown"

## The folder containing the repo
gRepo=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## The SMBIOS product name, can be changed (recommended: iMac13,1 or iMac13,2)
gProductName="iMac13,2"

## The location where the EFI partition is mounted, will be properly initialized later
gEFIMount="Unknown"

## Styling stuff
STYLE_RESET="\e[0m"
STYLE_BOLD="\e[1m"
STYLE_UNDERLINED="\e[4m"

## Color stuff
COLOR_BLACK="\e[1m"
COLOR_RED="\e[1;31m"
COLOR_GREEN="\e[32m"
COLOR_DARK_YELLOW="\e[33m"
COLOR_MAGENTA="\e[1;35m"
COLOR_PURPLE="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_BLUE="\e[1;34m"
COLOR_ORANGE="\e[31m"
COLOR_GREY="\e[37m"
COLOR_END="\e[0m"

#-------------------------------------------------------------------------------#
function _printError()
{
	# Initialize variables
	text="$1"

	# Print the error text and exit
	printf "${COLOR_RED}${STYLE_BOLD}ERROR: ${STYLE_RESET}${STYLE_BOLD}$text${STYLE_RESET} Exiting...\n"
	exit 1
}

function _identifyMotherboard()
{
	# Initialize variables
	motherboard=$(ioreg -lw0 -p IODeviceTree | grep "OEMBoard" | awk '{ print $4 }' | sed 's/<"//g' | sed 's/">//g')

	# Identify the motherboard
	case $motherboard in
		'B75M-D3H') gMotherboard="B75M-D3H";;
		'Z77X-D3H') gMotherboard="Z77X-D3H";;
		'Z77X-UD3H') gMotherboard="Z77X-UD3H";;
		'Z77X-UD4H') gMotherboard="Z77X-UD4H";;
		#'Z77X-UP4')
		#	gMotherboard="UP4-TH" # Not sure about this one...
		'Z77X-UD5H') gMotherboard="Z77X-UD5H";;
		'Z77X-UP5') gMotherboard="Z77X-UP5-TH";;
		'Z77X-UP7') gMotherboard="Z77X-UP7";;
		*) _printError "$motherboard is unsupported by this script!";;
	esac
}

function _checkOSVersion()
{
	osVersion=$(sw_vers -productVersion)

	case "$osVersion" in
		10.9* | 10.10* | 10.11*);; # Supported OS version detected, so do nothing
		*) _printError "OS X Version $osVersion is unsupported by this script!";;
	esac
}

function _printHeader()
{
	# Initialize variables
	args="$1"
	boardSeries=$(echo $gMotherboard | cut -d '-' -f 1)
	board=$(echo "${gMotherboard/$boardSeries-}")

	clear

	# Print the header & info
	echo "Gigabyte GA-Z77X.sh Post-Install Script v$gScriptVersion by theracermaster"
	echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
	echo "--------------------------------------------------------------------------------"
	printf "Detected motherboard: Gigabyte ${STYLE_BOLD}GA-$boardSeries-${COLOR_CYAN}$board${STYLE_RESET}\n"
	printf "Script arguments: ./GA-Z77X.sh $args\n"
	echo "--------------------------------------------------------------------------------"
}

function _checkRoot()
{
	if [ $gID -ne 0 ]; then
		# Re-run the script as root
		printf "This part of the script ${STYLE_UNDERLINED}needs${STYLE_RESET} to be run as root.\n"
		sudo clear
	fi
}

function _mountEFI()
{
	# Find the BSD device name for the current OS disk
	osVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)

	# Find the EFI partition of the disk
	efiVolume=$(diskutil list "$osVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')

	# Check if the EFI partition is already mounted; if not, mount it
	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI system partition ($efiVolume) mounted at $mountPoint."
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI system partition ($efiVolume) is already mounted at $mountPoint."
	fi

	gEFIMount="$mountPoint"
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
	# Initialize variables
	atherosNIC=$("$gRepo/tools/dspci" | grep "Ethernet controller" | grep "1969" | cut -d ':' -f 4 | cut -d ']' -f 1)

	# Gigabyte shipped different revisions of boards with different Atheros NICs
	# AtherosL1cEthernet supports AR8151, while AtherosE2200Ethernet supports AR8161
	# Install the correct Atheros kext if an Atheros NIC is detected
	if [[ ! -z $atherosNIC ]]; then
		case $atherosNIC in
			1083) # Atheros AR8151 v2.0 GbE - use AtherosL1cEthernet
				echo " - Atheros AR8151 v2.0 [1969:1083] detected, installing AtherosL1cEthernet.kext..."
				_installKextEFI "$gRepo/kexts/lan/AtherosL1cEthernet.kext";;
			1091) # Atheros AR8161 GbE - use AtherosE2200Ethernet
				echo " - Atheros AR8161 [1969:1091] detected, installing AtherosE2200Ethernet.kext..."
				_installKextEFI "$gRepo/kexts/lan/AtherosE2200Ethernet.kext";;
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
				echo " - Intel 82579V [8086:1503] detected, installing IntelMausiEthernet.kext..."
				_installKextEFI "$gRepo/kexts/lan/IntelMausiEthernet.kext"
				case $gMotherboard in
					"Z77X-UD5H" | "Z77X-UP7") # Motherboards that have dual NICs
						/usr/libexec/PlistBuddy -c "Merge $gRepo/patches/DualNIC_GLAN-ETH1.plist ':ACPI:DSDT:Patches'" "$gEFIMount/EFI/CLOVER/config.plist";;
					*) Otherwise assume that the motherboard has a single Intel NIC
						/usr/libexec/PlistBuddy -c "Merge $gRepo/patches/SingleNIC_GLAN-GIGE.plist ':ACPI:DSDT:Patches'" "$gEFIMount/EFI/CLOVER/config.plist";;
				esac;;
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
				echo " - Realtek RTL8168/RTL8111 [10ec:8168] detected, installing RealtekRTL8111.kext..."
				_installKextEFI "$gRepo/kexts/lan/RealtekRTL8111.kext";;
		esac
	fi
}

function _detectMarvellSATA()
{
	# Initialize variables
	marvellSATA=$("$gRepo/tools/dspci" | grep "SATA controller" | grep "1b4b")

	# Install AHCI_3rdParty_SATA if Marvell SATA controllers are detected
	if [[ ! -z $marvellSATA ]]; then
		echo " - Marvell SATA controller(s) detected, installing AHCI_3rdParty_SATA.kext..."
		_installKextEFI "$gRepo/kexts/sata/AHCI_3rdParty_SATA.kext"
	fi
}

function _detectUSB()
{
	# Initialize variables
	plist="$gEFIMount/EFI/CLOVER/config.plist"
	xhciList=$("$gRepo/tools/dspci" | grep "xHCI\|USB 3.0")
	nonIntelXHCI=$(echo $xhciList | grep -Fv "8086")

	# Add AppleUSBXHCI kext patches for non-Intel xHCI controllers to config.plist
	## Make sure config.plist exists
	if [ ! -f "$plist" ]; then
		_printError "config.plist not found!"
		exit 1
	fi
	## Add the kext patches to config.plist
	if [[ ! -z $nonIntelXHCI ]]; then
		echo " - Non-Intel xHCI contoller(s) detected, enabling AppleUSBXHCI kext patches..."
		/usr/libexec/PlistBuddy -c "Merge $gRepo/patches/$osVersion-AppleUSBXHCI.plist ':KernelAndKextPatches:KextsToPatch'" $plist
	fi
}

function _detectPS2()
{
	case $gMotherboard in
		"B75M-D3H" | "Z77X-D3H" | "Z77X-UD3H" | "Z77X-UD4H" | "Z77X-UP7") # Motherboards that have a PS/2 port
			echo " - PS/2 hardware present, installing VoodooPS2Controller..."
			_installKextEFI "$gRepo/kexts/misc/VoodooPS2Controller.kext";;
	esac
}

function _genSMBIOSData()
{
	# Initialize variables
	printf "${STYLE_BOLD}Generating SMBIOS data${STYLE_RESET}:\n"
	plist="$gEFIMount/EFI/CLOVER/config.plist"

	# Make sure config.plist exists
	if [ ! -f "$plist" ]; then
		_printError "config.plist not found!"
		exit 1
	fi

	# TODO: Better error handling if simpleMLB.sh says the serial number is invalid
	serialNumber=$(externals/simpleMacSerial.sh/simpleMacSerial.sh $gProductName)
	MLB=$(externals/simpleMLB.sh/simpleMLB.sh $serialNumber)
	SmUUID=$(uuidgen)

	echo " - Product Name: $gProductName"
	echo " - Serial Number: $serialNumber"
	echo " - MLB Serial Number: $MLB"
	echo " - System UUID: $SmUUID"

	# Copy the generated data to the plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:ProductName '$gProductName'" "$plist"
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" "$plist"
	/usr/libexec/plistbuddy -c "Set :RtVariables:MLB '$MLB'" "$plist"
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SmUUID '$SmUUID'" "$plist"

	printf "\n${STYLE_BOLD}Press enter to continue...${STYLE_RESET}\n" && read
}

function _generateSSDT_PR()
{
	# Initialize variables
	printf "${STYLE_BOLD}Generating SSDT for power management${STYLE_RESET}:\n"
	maxTurboFreq="$(bdmesg | grep Turbo: | cut -d '/' -f2)00"

	# Download ssdtPRGen.sh & the CPU data
	curl -o ~/Library/ssdtPRGen.zip https://codeload.github.com/Piker-Alpha/ssdtPRGen.sh/zip/Beta
	unzip -qu ~/Library/ssdtPRGen.zip -d ~/Library/
	mv ~/Library/ssdtPRGen.sh-Beta ~/Library/ssdtPRGen
	rm ~/Library/ssdtPRGen.zip

	# Generate an SSDT for power management
	yes n | ~/Library/ssdtPRGen/ssdtPRGen.sh -turbo "$maxTurboFreq" -x 1

	# Copy the generated SSDT to the Clover ACPI/patched folder on the EFI partition
	cp ~/Library/ssdtPRGen/ssdt.aml "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT.aml"

	printf "${STYLE_BOLD}Press enter to continue...${STYLE_RESET}\n" && read
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

function _compileSSDT()
{
	# Clear the output and print the header
	_printHeader "${STYLE_BOLD}--install-ssdt: ${COLOR_BLUE}Compiling Custom SSDT${STYLE_RESET}"

	# Mount the EFI partition
	_mountEFI

	# Initialize variables
	fileName="SSDT-GA-$gMotherboard.dsl"
	url="https://raw.githubusercontent.com/theracermaster/DSDT/master/$fileName"

	# Download the file
	printf "${STYLE_BOLD}Downloading $fileName${STYLE_RESET}:\n"
	curl --output "/tmp/$fileName" --progress-bar --location "$url"

	# Compile the SSDT and move it to the right directory
	printf "${STYLE_BOLD}Compiling $fileName${STYLE_RESET}:\n"
	"$gRepo/tools/iasl" "/tmp/$fileName"
	mv "/tmp/SSDT-GA-$gMotherboard.aml" "$gRepo/EFI/CLOVER/ACPI/patched/SSDT-HACK.aml"

	printf "\n${STYLE_BOLD}SSDT compilation complete.${STYLE_RESET} Exiting...\n"
	exit 0
}

function _injectHDA()
{
	# Initialize variables
	plist="$gRepo/EFI/CLOVER/config.plist"

	# Load AppleHDA.kext so we can ID the codec
	sudo kextload "/System/Library/Extensions/AppleHDA.kext" > /dev/null

	# Run the HDA injector script
	sudo "$gRepo/externals/hdaInjector.sh/hdaInjector.sh"

	# Copy config.plist and add the kext patches to it
	cp "$gRepo/config-generic.plist" "$plist"
	/usr/libexec/PlistBuddy -c "Merge /tmp/ktp.plist ':KernelAndKextPatches:KextsToPatch'" $plist

	exit 0
}

function _installClover()
{
	# Clear the output and print the header
	_printHeader "${STYLE_BOLD}--install-clover: ${COLOR_GREEN}Installing Clover Bootloader${STYLE_RESET}"

	# Find the BSD device name for the current OS disk
	osVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)

	# Find the EFI partition of the disk
	efiVolume=$(diskutil list "$osVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')

	# Check if the EFI partition is already mounted; if not, mount it
	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI system partition ($efiVolume) mounted at $mountPoint."
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI system partition ($efiVolume) is already mounted at $mountPoint."
	fi
	gEFIMount="$mountPoint"

	# Check if there is an existing bootloader install; if so, ask the user if it can be overwritten
	if [ -d "$gEFIMount/EFI/CLOVER" ]; then
		echo "An existing installation of Clover UEFI was found on the EFI system partition."
		printf "${STYLE_BOLD}Do you want to overwrite it (y/n)?${STYLE_RESET} "
		read choice
		case "$choice" in
			y|Y)
				echo "Removing existing Clover UEFI bootloader install..."
				rm -rf "$gEFIMount/EFI";;
			n|N)
				echo "Backing up existing Clover UEFI bootloader install..."
				mv "$gEFIMount/EFI/BOOT" "$gEFIMount/BOOTbackup"
				mv "$gEFIMount/EFI/CLOVER" "$gEFIMount/CLOVERbackup";;
		esac
	fi

	# Clear the output and reprint the header
	_printHeader "${STYLE_BOLD}--install-clover: ${COLOR_GREEN}Installing Clover Bootloader${STYLE_RESET}"

	# Copy the config.plist if wasn't automatically copied during HDA injection
	if [ ! -f "$gRepo/EFI/CLOVER/config.plist" ]; then
		cp "$gRepo/config-generic.plist" "$gRepo/EFI/CLOVER/config.plist"
	fi

	# Copy the directories to the EFI partition & create the kext directory
	mkdir -p "$gEFIMount/EFI/BOOT"
	cp -R "$gRepo/EFI/BOOT" "$gEFIMount/EFI"
	cp -R "$gRepo/EFI/CLOVER" "$gEFIMount/EFI"

	# Install the required kexts
	printf "${STYLE_BOLD}Installing required kexts${STYLE_RESET}:\n"
	## Install FVInjector.kext
	sudo cp -R "$gRepo/kexts/misc/FVInjector.kext" /Library/Extensions
	sudo chmod -R 755  "/Library/Extensions/FVInjector.kext"
	sudo chown -R 0:0 "/Library/Extensions/FVInjector.kext"
	## Check what other kexts/patches are needed and install them
	_detectAtherosNIC
	_detectIntelNIC
	_detectRealtekNIC
	_detectMarvellSATA
	_detectPS2

	# Generate the SMBIOS data
	_genSMBIOSData

	# Generate an SSDT for power management using ssdtPRGen.sh
	_generateSSDT_PR

	# Clear the output and reprint the header
	_printHeader "${STYLE_BOLD}--install-clover: ${COLOR_GREEN}Installing Clover Bootloader${STYLE_RESET}"

	# Rebuld kext caches
	printf "${STYLE_BOLD}Rebuilding kext caches${STYLE_RESET}:\n"
	sudo kextcache -system-prelinked-kernel
	sudo kextcache -system-caches

	# We're done here, let's prompt the user to reboot
	printf "\n${STYLE_BOLD}Clover installation complete. Do you want to reboot now (y/n)?${STYLE_RESET} "
	read choice
	case "$choice" in
		y|Y) # User said yes, so let's reboot
			echo "Rebooting..."
			sudo reboot;;
		*) # Anything else, let's just quit
			echo "Exiting..."
			exit 0;;
	esac
}

function _cleanup()
{
	_printHeader "${STYLE_BOLD}--cleanup: ${COLOR_RED}Deleting Generated Repo Files${STYLE_RESET}"

	# Make sure we're in the repo folder
	cd "$gRepo"

	# Delete the generated files
	printf "${STYLE_BOLD}Deleting generated files in repo folders${STYLE_RESET}:\n"
	sudo rm -rf *.kext
	rm -f EFI/CLOVER/ACPI/patched/*.aml
	rm -f EFI/CLOVER/config.plist
	rm -f /tmp/*.aml
	rm -f /tmp/*.dsl
	sudo rm -rf /tmp/*.plist

	# Exit once it's done
	printf "\n${STYLE_BOLD}Cleanup complete.${STYLE_RESET} Exiting...\n"
	exit 0
}
#-------------------------------------------------------------------------------#

_identifyMotherboard
_checkOSVersion

case "$1" in
	--git-update)
		_gitUpdate;;
	--compile-ssdt)
		_compileSSDT;;
	--inject-hda)
		_checkRoot
		_injectHDA;;
	--install-clover)
		_checkRoot
		_installClover;;
	--cleanup)
		_checkRoot
		_cleanup;;
	*)
		echo "Gigabyte GA-Z77X.sh Post-Install Script v$gScriptVersion by theracermaster"
		echo "Supports various Gigabye GA-Z77X motherboards running OS X 10.9+"
		echo
		echo "Usage: ./GA-Z77X.sh <command>, where <command> is one of the following:"
		echo
		echo "     --git-update         Update the repo & helper files to the latest version"
		echo "     --compile-ssdt       Download & compile the SSDT for your motherboard"
		echo "     --inject-hda         Install the injector kext for your audio codec"
		echo "     --install-clover     Install Clover UEFI to your EFI system partition"
		echo "     --cleanup            Delete files generated by this script in repo folders"
		echo
		echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
esac

exit 0
