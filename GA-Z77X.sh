#!/usr/local/bin/bash
#
# GA-Z77X.sh - Gigabyte GA-Z77X macOS Post-Install Script by theracermaster
# Gigabyte GA-Z77X DSDT Patch Repo - https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch

# Global variables
## The script version
gScriptVersion="2.0"

## The repo folder
gRepo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

## The motherboard, will be properly initialized later
gMotherboard="Unknown"
## The CPU microarchitecture, 2 = Sandy Bridge, 3 = Ivy Bridge
gCoreBridgeType=$(sysctl -n machdep.cpu.brand_string | cut -d '-' -f 2 | cut -c 1)
## The HDEF layout ID
gLayoutID=0
## PS/2 support, 0 = no, 1 = yes
gPS2=0

## The default Mac model (recommended: iMac13,1 or iMac13,2)
gProductName="iMac13,2"

source "$gRepo/tools/common.sh"

function _gitUpdate()
{
	cd "$gRepo"

	git pull

	# Update the submodules
	git submodule update --init --recursive
	git submodule foreach git pull origin master
}

function _identifyMotherboard()
{
	# Initialize variables
	motherboard=$(ioreg -k OEMBoard -p IODeviceTree | awk '/OEMBoard/ {print $4}' | tr -d '<"">')

	# Identify the motherboard
	case $motherboard in
		#'B75M-D3H')
		#	gMotherboard="B75M-D3H"
		#	gLayoutID=1
		#	;;
		'Z77X-D3H')
			gMotherboard="Z77X-D3H"
			gLayoutID=5
			gPS2=1
			;;
		'Z77X-UD3H')
			gMotherboard="Z77X-UD3H"
			gLayoutID=5
			gPS2=1
			;;
		#'Z77X-UD4H')
		#	gMotherboard="Z77X-UD4H"
		#	gLayoutID=1
		#	;;
		'Z77X-UD5H')
			gMotherboard="Z77X-UD5H"
			gLayoutID=1
			;;
		'Z77X-UP5')
			gMotherboard="Z77X-UP5-TH"
			gLayoutID=1
			;;
		#'Z77X-UP7')
		#	gMotherboard="Z77X-UP7"
		#	gLayoutID=1
		#	;;
		*)
			_printError "$motherboard is unsupported by this script!"
			;;
	esac
}

function _checkOSVersion()
{
	case $gOSVersion in
		10.11 | 10.12)
			;; # Supported OS version detected, so do nothing
		*)
			_printError "macOS Version $gOSVersion is unsupported by this script!";;
	esac
}

function _printHeader()
{
	# Initialize variables
	boardSeries=$(echo $gMotherboard | cut -d '-' -f 1)
	board=$(echo "${gMotherboard/$boardSeries-}")

	clear

	# Print the header & info
	echo "Gigabyte GA-Z77X.sh Post-Install Script v$gScriptVersion by theracermaster"
	echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
	echo "--------------------------------------------------------------------------------"
	printf "Detected motherboard: Gigabyte ${STYLE_BOLD}GA-$boardSeries-${COLOR_CYAN}$board${STYLE_RESET}\n"
	printf "Script arguments: ./GA-Z77X.sh $1\n"
	echo "--------------------------------------------------------------------------------"
}

function _detectAtherosNIC()
{
	# Gigabyte shipped different revisions of boards with different Atheros NICs
	# AtherosL1cEthernet supports AR8151, while AtherosE2200Ethernet supports AR8161
	# Install the correct Atheros kext if an Atheros NIC is detected
	if [ ! -z "$(_checkDevicePresence 1969 1083)" ]; then
 		# Atheros AR8151 v2.0 GbE - use AtherosL1cEthernet
		echo " - Atheros AR8151 v2.0 GbE [1969:1083] detected, installing AtherosL1cEthernet.kext..."
		_installKextEFI "$gRepo/drivers/kexts/AtherosL1cEthernet.kext"
	elif [ ! -z "$(_checkDevicePresence 1969 1091)" ]; then
		echo " - Atheros AR8161 GbE [1969:1091] detected, installing AtherosE2200Ethernet..."
		_installKextEFI "$gRepo/drivers/kexts/AtherosE2200Ethernet.kext"
	fi
}

function _detectIntelNIC()
{
	if [ ! -z "$(_checkDevicePresence 8086 1503)" ]; then
 		# Intel 82579V GbE - use IntelMausiEthernet
		echo " - Intel 82579V GbE [8086:1503] detected, installing IntelMausiEthernet..."
		_installKextEFI "$gRepo/drivers/kexts/IntelMausiEthernet.kext"
		case $gMotherboard in
			"Z77X-UD5H" | "Z77X-UP7") # Motherboards that have dual NICs
				/usr/libexec/PlistBuddy -c "Merge $gRepo/config/patches/acpi_DualLAN.plist ':ACPI:DSDT:Patches'" "$gEFIMount/EFI/CLOVER/config.plist"
				;;
			*) # Otherwise assume that the motherboard has a single Intel NIC
				/usr/libexec/PlistBuddy -c "Merge $gRepo/config/patches/acpi_SingleLAN.plist ':ACPI:DSDT:Patches'" "$gEFIMount/EFI/CLOVER/config.plist"
				;;
		esac
	fi
}

function _detectRealtekNIC()
{
	if [ ! -z "$(_checkDevicePresence 10ec 8168)" ]; then
 		# Realtek RTL8168/RTL8111 GbE - use RealtekRTL8111
		echo " - Realtek RTL8168/RTL8111 GbE [10EC:8168] detected, installing RealtekRTL8111..."
		_installKextEFI "$gRepo/drivers/kexts/RealtekRTL8111.kext"
	fi
}

function _detectMarvellSATA()
{
	if [ ! -z "$(_checkDevicePresence 1b4b 9172)" ]; then
 		# Marvell 88SE9172 SATA - use GenericAHCIPort
		echo " - Marvell 88SE9172 SATA [1B4B:9172] detected, installing GenericAHCIPort..."
		_installKextEFI "$gRepo/drivers/kexts/GenericAHCIPort.kext"
	fi
}

function _detectXHCI()
{
	# Add AppleUSBXHCIPCI injector for non-Intel xHCI controllers
	if [ ! -z "$(_checkDevicePresence 1106 3432)" ]; then
		echo " - VIA VL800 xHCI [1106:3432] detected, installing GenericUSBXHCIPCI.kext..."
		_installKextEFI "$gRepo/drivers/kexts/GenericUSBXHCIPCI.kext"
	#elif [ ! -z "$(_checkDevicePresence 1B6F 7023)" ]; then
	#	echo " - Etron EJ168 xHCI [1B6F:7023] detected, installing GenericUSBXHCIPCI.kext..."
	#	_installKextEFI "$gRepo/drivers/kexts/GenericUSBXHCIPCI.kext"
	fi
}

function _detectFireWire()
{
	# Initialize variables
	plist="$gEFIMount/EFI/CLOVER/config.plist"

	# Add EFI driver to fix GUID issues with built-in FireWire
	## Add the kext patches to config.plist if non-Intel xHCI controllers (VIA VL810/Etron EJ168) are present
	if [ ! -z "$(_checkDevicePresence 1106 3044)" ]; then
		echo " - VIA VT6308 FireWire OHCI [1106:3044] detected, installing EFI drivers..."
		cp "$gRepo/drivers/efi/FireWireDevice.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/FireWireDevice.efi"
		cp "$gRepo/drivers/efi/FireWireOhci.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/FireWireOhci.efi"
	fi
}

function _detectThunderbolt()
{
	# Add SSDT to (potentially) fix some Thunderbolt issues
	if [ ! -z "$(_checkDevicePresence 8086 1547)" ]; then
		echo " - Compiling SSDT-TB.dsl..."
		iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-TB.aml" "$gRepo/acpi/common/SSDT-TB.dsl" |& tail -n 1
	fi

	echo
}

function _detectPS2()
{
	if [ $gPS2 -eq 1 ]; then
		echo " - PS/2 hardware present, installing VoodooPS2Controller..."
		_installKextEFI "$gRepo/drivers/kexts/VoodooPS2Controller.kext"
	fi
}

function _compileACPI()
{
	# Initialize variables
	iasl="$gRepo/tools/iasl"
	ssdtCFG="SSDT-CFG-$boardSeries-$board.dsl"

	# Compile ACPI source files and move output files to the ESP
	echo " - Compiling $ssdtCFG:"
	iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-CFG.aml" "$gRepo/acpi/$ssdtCFG" |& tail -n 1
	echo " - Compiling SSDT-HDA.dsl:"
	iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-HDA.aml" "$gRepo/acpi/common/SSDT-HDA.dsl" |& tail -n 1
	echo " - Compiling SSDT-IGPU.dsl:"
	iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-IGPU.aml" "$gRepo/acpi/common/SSDT-IGPU.dsl" |& tail -n 1
	echo " - Compiling SSDT-PEG.dsl:"
	iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-PEG.aml" "$gRepo/acpi/common/SSDT-PEG.dsl" |& tail -n 1
	echo " - Compiling SSDT-USB.dsl:"
	iasl -p "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-USB.aml" "$gRepo/acpi/common/SSDT-USB.dsl" |& tail -n 1
}

function _install()
{
	# Mount the EFI system partition
	_mountEFI

	# Clear the output and print the header
	_printHeader "${STYLE_BOLD}--install: ${COLOR_GREEN}Installing Clover Bootloader${STYLE_RESET}"

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
	_printHeader "${STYLE_BOLD}--install: ${COLOR_GREEN}Installing Clover Bootloader${STYLE_RESET}"

	# Copy Clover files/folders
	mkdir -p "$gEFIMount/EFI"
	cp -R "$gRepo/efi/BOOT" "$gEFIMount/EFI"
	cp -R "$gRepo/efi/CLOVER" "$gEFIMount/EFI"
	cp "$gRepo/config/config_main.plist" "$gEFIMount/EFI/CLOVER/config.plist"

	printf "${STYLE_BOLD}Installing required kexts${STYLE_RESET}:\n"
	# Install the required kexts
	_installKextEFI "$gRepo/drivers/kexts/FakeSMC.kext"
	_installKextEFI "$gRepo/drivers/kexts/AppleALC.kext"
	_installKextEFI "$gRepo/drivers/kexts/Shiki.kext"

	# Install kexts for other detected hardware
	_detectAtherosNIC
	_detectIntelNIC
	_detectRealtekNIC
	_detectMarvellSATA
	_detectXHCI
	_detectPS2

	# Set layout ID in config.plis
	/usr/libexec/PlistBuddy -c "Set ':Devices:Audio:Inject' $gLayoutID" "$gEFIMount/EFI/CLOVER/config.plist"

	# Install the required UEFI drivers
	cp "$gRepo/drivers/efi/EfiDevicePathPropertyDatabase.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/EfiDevicePathPropertyDatabase.efi"
	cp "$gRepo/drivers/efi/FSInject.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/FSInject.efi"
	cp "$gRepo/drivers/efi/HfsPlus.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/HfsPlus.efi"
	cp "$gRepo/drivers/efi/OsxAptioFix2Drv.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/OsxAptioFix2Drv.efi"
	cp "$gRepo/drivers/efi/PartitionDxe.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi/PartitionDxe.efi"

	# Install the FireWire EFI drivers (if needed)
	_detectFireWire

	# Generate the SMBIOS data
	_genSMBIOSData

	# Clear the output and reprint the header
	printf "\n${STYLE_BOLD}Press enter to continue...${STYLE_RESET}\n" && read
	_printHeader "${STYLE_BOLD}--install: ${COLOR_BLUE}Compiling ACPI Source Files${STYLE_RESET}"

	# Compile ACPI source files
	printf "${STYLE_BOLD}Compiling SSDTs${STYLE_RESET}:\n"
	_compileACPI
	_detectThunderbolt

	# We're done here, let's prompt the user to reboot
	printf "${STYLE_BOLD}Installation complete. Do you want to reboot now (y/n)?${STYLE_RESET} " && read choice
	case "$choice" in
		y|Y) # User said yes, so let's reboot
			echo "Rebooting..."
			sudo reboot
			;;
		*) # Anything else, let's just quit
			echo "Exiting..."
			exit 0
			;;
	esac

}

_identifyMotherboard
_checkOSVersion

case "$1" in
#	--git-update)
#		gitUpdate
#		;;
	--install)
		_gitUpdate
		_install
		;;
	*)
		echo "Gigabyte GA-Z77X.sh Post-Install Script v$gScriptVersion by theracermaster"
		echo "Supports various Gigabye GA-Z77X motherboards running macOS 10.10+"
		echo
		echo "Usage: ./GA-Z77X.sh <command>, where <command> is one of the following:"
		echo
		echo "     --git-update         Update the repo to the latest version"
		echo "     --install            Install Clover UEFI to your EFI system partition"
		echo
		echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
esac

exit 0
