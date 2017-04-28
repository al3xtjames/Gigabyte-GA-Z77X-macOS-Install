#!/usr/bin/env bash
# GA-Z77X.sh - GA-Z77X Series macOS Post-Installation Script

set -e
set -u

# GA-Z77X.sh script version
gScriptVersion="2.0.7"

# Styles
gStyleReset="\e[0m"
gStyleBold="\e[1m"
gStyleUnderlined="\e[4m"
# Colors
gColorBlack="\e[1m"
gColorRed="\e[1;31m"
gColorGreen="\e[32m"
gColorDarkYellow="\e[33m"
gColorMagenta="\e[1;35m"
gColorPurple="\e[35m"
gColorCyan="\e[36m"
gColorBlue="\e[1;34m"
gColorOrange="\e[31m"
gColorGrey="\e[37m"

# The repo folder
gRepo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# The user ID
gID=$(id -u)
# The major version of macOS
gOSVersion=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
# The CPU microarchitecture, 2 = Sandy Bridge, 3 = Ivy Bridge
gCoreBridgeType=$(sysctl -n machdep.cpu.brand_string | cut -d '-' -f 2 | cut -c 1)
# SMBIOS product name (Mac model)
gProductName="iMac13,2"

function usage()
{
	echo "GA-Z77X.sh v$gScriptVersion"
	echo "Gigabyte GA-Z77X Series Post-Install Script by theracermaster"
	echo
	echo "Usage: ./GA-Z77X.sh <command>"
	echo
	echo "     --install               Install Clover/kexts/ACPI to the ESP"
	echo "     --update                Update Clover/kexts/ACPI on the ESP"
	echo "     --help (-h)             Help (this screen)"
	echo
	exit 0
}

function print_header()
{
	# Initialize variables
	local boardSeries=$(echo $gMotherboard | cut -d '-' -f 1)
	local board=$(echo "${gMotherboard/$boardSeries-}")

	clear

	# Print the header & info
	echo   "Gigabyte GA-Z77X Series Post-Install Script v$gScriptVersion by theracermaster"
	printf "Updates & info: %bhttps://github.com/theracermaster/Gigabyte-GA-Z77X-macOS-Install%b\n" $gStyleUnderlined $gStyleReset
	echo   "--------------------------------------------------------------------------------"
	printf "Detected motherboard: Gigabyte %bGA-%s-%b%s%b\n" $gStyleBold $boardSeries $gColorCyan $board $gStyleReset
	printf "Script arguments: ./GA-Z77X.sh $1\n"
	echo   "--------------------------------------------------------------------------------"
}

function print_error()
{
	# Print the error text and exit
	printf "%b%bERROR: %b%s\n" $gColorRed $gStyleBold $gStyleReset "$1"
	exit 1
}

function git_update()
{
	cd "$gRepo"

	git pull
	# Update the submodules
	# git submodule update --init --recursive
	# git submodule foreach git pull origin HEAD
}

function check_macos_version()
{
	case $gOSVersion in
		10.12)
			;; # Supported OS version detected, so do nothing
		*)
			print_error "macOS $gOSVersion is unsupported by this script!"
			;;
	esac
}

function check_motherboard()
{
	local motherboard=$(ioreg -k OEMBoard -p IODeviceTree | awk '/OEMBoard/ {print $4}' | tr -d '<"">')
	# Identify the motherboard
	case $motherboard in
		'Z77M-D3H')
			gMotherboard="Z77M-D3H"
			gLayoutID=5
			;;
		'Z77X-D3H')
			gMotherboard="Z77X-D3H"
			gLayoutID=5
			;;
		'Z77X-UD3H')
			gMotherboard="Z77X-UD3H"
			gLayoutID=5
			;;
		'Z77X-UP4')
			gMotherboard="Z77X-UP4-TH"
			gLayoutID=3
			;;
		'Z77X-UD5H')
			gMotherboard="Z77X-UD5H"
			gLayoutID=3
			;;
		'Z77X-UP5')
			gMotherboard="Z77X-UP5-TH"
			gLayoutID=3
			;;
		*)
			print_error "$motherboard is unsupported by this script!"
			;;
	esac
}

function check_root()
{
	if [ $(id -u) -ne 0 ]; then
		# Re-run the script as root
		printf "This part of the script %bneeds%b to be run as root.\n" $gStyleBold $gStyleReset
		sudo clear
	fi
}

function check_device_presence()
{
	# Look for a PCI device in bdmesg
	"$gRepo/tools/bdmesg" | grep "$1 $2"
}

# Credit to RehabMan
function replace_plist_dict()
{
	# $1 is path to replace
	if [ $gCoreBridgeType -eq 3 ]; then
		/usr/libexec/PlistBuddy -x -c "Print \"$1\"" "$gRepo/config/config_main_ivy.plist" > /tmp/org_rehabman_node.plist
	else
		/usr/libexec/PlistBuddy -x -c "Print \"$1\"" "$gRepo/config/config_main_sandy.plist" > /tmp/org_rehabman_node.plist
	fi
	/usr/libexec/PlistBuddy -c "Delete \"$1\"" "$gEFIMount/EFI/CLOVER/config.plist"
	/usr/libexec/PlistBuddy -c "Add \"$1\" dict" "$gEFIMount/EFI/CLOVER/config.plist"
	/usr/libexec/PlistBuddy -c "Merge /tmp/org_rehabman_node.plist \"$1\"" "$gEFIMount/EFI/CLOVER/config.plist"
}

function detect_atheros_nic()
{
	# Gigabyte shipped different revisions of boards with different Atheros NICs
	# AtherosL1cEthernet supports AR8151, while AtherosE2200Ethernet supports AR8161
	# Install the correct Atheros kext if an Atheros NIC is detected
	if [ ! -z "$(check_device_presence 1969 1083)" ]; then
 		# Atheros AR8151 v2.0 GbE - use AtherosL1cEthernet
		echo " - Atheros AR8151 v2.0 GbE [1969:1083] detected, installing AtherosL1cEthernet..."
		cp -R "$gRepo/kexts/AtherosL1cEthernet.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	elif [ ! -z "$(check_device_presence 1969 1091)" ]; then
		echo " - Atheros AR8161 GbE [1969:1091] detected, installing AtherosE2200Ethernet..."
		cp -R "$gRepo/kexts/AtherosE2200Ethernet.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	fi
}

function detect_intel_nic()
{
	if [ ! -z "$(check_device_presence 8086 1503)" ]; then
 		# Intel 82579V GbE - use IntelMausiEthernet
		echo " - Intel 82579V GbE [8086:1503] detected, installing IntelMausiEthernet..."
		cp -R "$gRepo/kexts/IntelMausiEthernet.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	fi
}

function detect_realtek_nic()
{
	if [ ! -z "$(check_device_presence 10EC 8168)" ]; then
 		# Realtek RTL8168/RTL8111 GbE - use RealtekRTL8111
		echo " - Realtek RTL8168/RTL8111 GbE [10EC:8168] detected, installing RealtekRTL8111..."
		cp -R "$gRepo/kexts/RealtekRTL8111.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	fi
}

function detect_marvell_sata()
{
	if [ ! -z "$(check_device_presence 1B4B 9172)" ]; then
		# Marvell 88SE9172 SATA - use GenericAHCIPort injector
		echo " - Marvell 88SE9172 SATA [1B4B:9172] detected, installing GenericAHCIPort..."
		cp -R "$gRepo/kexts/GenericAHCIPort.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	fi
}

function detect_generic_xhci()
{
	if [ ! -z "$(check_device_presence 1106 3432)" ]; then
		# Add GenericUSBXHCI for non-Intel xHCI controllers
		echo " - VIA VL800 xHCI [1106:3432] detected, installing GenericUSBXHCI.kext..."
		cp -R "$gRepo/kexts/GenericUSBXHCI.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	fi
}

function detect_firewire()
{
	# Add Apple EFI drivers to fix GUID issues/inject device properties for FireWire
	if [ ! -z "$(check_device_presence 1106 3044)" ]; then
		echo " - VIA VT6308 FireWire OHCI [1106:3044] detected, installing EFI drivers..."
		cp "$gRepo/efi/drivers/FireWireDevice.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
		cp "$gRepo/efi/drivers/FireWireOhci.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	fi
}

function detect_thunderbolt()
{
	# Add Apple EFI drivers to inject device properties for Thunderbolt
	if [ ! -z "$(check_device_presence 8086 1547)" ]; then
		echo " - Intel DSL3510 Thunderbolt [8086:1547] detected, installing EFI drivers..."
		cp "$gRepo/efi/drivers/ThunderboltNhi.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
		cp "$gRepo/efi/drivers/ThunderboltXDomainDevice.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	fi
}

function install()
{
	# Mount the EFI system partition
	gEFIMount=$("$gRepo/acpi/build/tools/mount_efi.sh")

	local date="$(date '+%Y-%m-%d %Hh %Mm %Ss')"
	# Check if we are upgrading a current install
	if [ $1 -eq 1 ]; then
		# Clear the output and print the header
		print_header "${gStyleBold}--update: ${gColorGreen}Updating Clover & kexts${gStyleReset}"
		# Back up the current EFI folder on the ESP
		mkdir -p "$gRepo/backups/EFI ($date)"
		cp -R "$gEFIMount/EFI/" "$gRepo/backups/EFI ($date)"
		printf "%bCurrent EFI folder copied to:%b %bbackups/EFI ($date)%b\n" $gStyleBold $gStyleReset $gStyleUnderlined $gStyleReset
	else
		# Clear the output and print the header
		print_header "${gStyleBold}--install: ${gColorGreen}Installing Clover & kexts${gStyleReset}"
		# Check if there is an existing bootloader install; if so, ask the user if it can be overwritten
		if [ -d "$gEFIMount/EFI/CLOVER" ]; then
			echo "An existing installation of Clover was found on the EFI system partition."
			printf "%bDo you want to overwrite it (y/n)?%b " $gStyleBold $gStyleReset
			read choice
			case "$choice" in
				y|Y)
					echo "Removing existing Clover bootloader install..."
					rm -rf "$gEFIMount/EFI/CLOVER"
					;;
				n|N)
					echo "Backing up existing Clover bootloader install..."
					# Back up the current EFI folder on the ESP
					mkdir -p "$gRepo/backups/EFI ($date)"
					cp -R "$gEFIMount/EFI/" "$gRepo/backups/EFI ($date)"
					;;
			esac
			# Clear the output and print the header
			print_header "${gStyleBold}--install: ${gColorGreen}Installing Clover & kexts${gStyleReset}"
		fi
	fi

	# Prevent Spotlight from indexing the ESP
	touch "$gEFIMount/.metadata_never_index"

	# Copy Clover files/folders to the ESP
	mkdir -p "$gEFIMount/EFI/BOOT"
	mkdir -p "$gEFIMount/EFI/CLOVER/themes"
	cp "$gRepo/efi/CLOVERX64.efi" "$gEFIMount/EFI/BOOT/BOOTX64.efi"
	cp -R "$gRepo/efi/themes" "$gEFIMount/EFI/CLOVER"
	cp -R "$gRepo/efi/tools" "$gEFIMount/EFI/CLOVER"

	if [ $1 -eq 1 ]; then
		# Update config.plist
		replace_plist_dict ":ACPI"
		replace_plist_dict ":Boot"
		replace_plist_dict ":Devices"
		replace_plist_dict ":KernelAndKextPatches"
		replace_plist_dict ":SystemParameters"
	else
		# Generate config.plist
		if [ $gCoreBridgeType -eq 3 ]; then
			cp "$gRepo/config/config_main_ivy.plist" "$gEFIMount/EFI/CLOVER/config.plist"
		else
			cp "$gRepo/config/config_main_sandy.plist" "$gEFIMount/EFI/CLOVER/config.plist"
		fi
		# Set the HDA layout ID
		/usr/libexec/PlistBuddy -c "Set ':Devices:Audio:Inject' $gLayoutID" "$gEFIMount/EFI/CLOVER/config.plist"
		# Generate the SMBIOS data
		printf "%bGenerating SMBIOS data%b:\n" $gStyleBold $gStyleReset
		export MG_DEBUG=0
		local serialNumber=$("$gRepo/tools/MacGen/mg-serial" $gProductName)
		local mlbSerialNumber=$("$gRepo/tools/MacGen/mg-mlb-serial" $gProductName $serialNumber)
		local smUUID=$(uuidgen)
		echo " - Product Name: $gProductName"
		echo " - Serial Number: $serialNumber"
		echo " - MLB Serial Number: $mlbSerialNumber"
		echo " - System UUID: $smUUID"
		/usr/libexec/PlistBuddy -c "Set :SMBIOS:ProductName '$gProductName'" "$gEFIMount/EFI/CLOVER/config.plist"
		/usr/libexec/PlistBuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" "$gEFIMount/EFI/CLOVER/config.plist"
		/usr/libexec/PlistBuddy -c "Set :RtVariables:MLB '$mlbSerialNumber'" "$gEFIMount/EFI/CLOVER/config.plist"
		/usr/libexec/PlistBuddy -c "Set :SMBIOS:SmUUID '$smUUID'" "$gEFIMount/EFI/CLOVER/config.plist"
	fi

	# Install bdmesg
	sudo mkdir -p /usr/local/bin
	sudo cp "$gRepo/tools/bdmesg" /usr/local/bin/bdmesg

	# Install mandatory EFI drivers
	if [ $1 -eq 1 ]; then
		rm -rf "$gEFIMount/EFI/CLOVER/drivers64uefi" > /dev/null
	fi
	mkdir -p "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/AppleImageCodec.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/AppleKeyMapAggregator.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/EfiDevicePathPropertyDatabase.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/HashServiceFix.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/HfsPlus.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/OsxAptioFix2Drv.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"
	cp "$gRepo/efi/drivers/UsbKbDxe.efi" "$gEFIMount/EFI/CLOVER/drivers64uefi"

	# Install mandatory kexts
	mkdir -p "$gEFIMount/EFI/CLOVER/kexts/Other"
	if [ "$1" -eq 1 ]; then
		printf "%bUpdating kexts%b:\n" $gStyleBold $gStyleReset
	else
		printf "%bInstalling kexts%b:\n" $gStyleBold $gStyleReset
	fi
	cp -R "$gRepo/kexts/AppleALC.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/CoreDisplayFixup.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/FakeSMC.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/HibernationFixup.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/IntelGraphicsFixup.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/Lilu.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"
	cp -R "$gRepo/kexts/Shiki.kext" "$gEFIMount/EFI/CLOVER/kexts/Other"

	# Install kexts/EFI drivers for detected hardware
	detect_atheros_nic
	detect_intel_nic
	detect_realtek_nic
	detect_marvell_sata
	detect_generic_xhci
	detect_firewire
	detect_thunderbolt

	# Install X86PlatformPlugin frequency vector injector
	echo " - XNU CPU Power Management enabled, installing 1155PlatformPlugin..."
	sudo cp -R "$gRepo/kexts/1155PlatformPlugin.kext" /Library/Extensions
	sudo chmod -R 755 /Library/Extensions/1155PlatformPlugin.kext
	sudo chown -R 0:0 /Library/Extensions/1155PlatformPlugin.kext
	sudo touch /System/Library/Extensions

	printf "\n%bPress enter to continue...%b\n" $gStyleBold $gStyleReset && read
	if [ "$1" -eq 1 ]; then
		# Clear the output and print the header
		print_header "${gStyleBold}--update: ${gColorGreen}Updating Clover & kexts${gStyleReset}"
	else
		# Clear the output and reprint the header
		print_header "${gStyleBold}--install: ${gColorGreen}Installing Clover & kexts${gStyleReset}"
	fi

	# Compile/copy DSDT
	mkdir -p "$gEFIMount/EFI/CLOVER/ACPI/origin"
	mkdir -p "$gEFIMount/EFI/CLOVER/ACPI/patched"
	printf "%bCompiling and copying DSDT%b:\n" $gStyleBold $gStyleReset
	BOARD="Gigabyte/GA-$gMotherboard" make install -C "$gRepo/acpi" | tail -n 2 | head -n 1
	# Generate SSDT for CPU PM
	local maxTurboFreq=$("$gRepo/tools/bdmesg" | awk '/Turbo:/ {print $4}' | tr / '\n' | awk 'NR==1 {max=$1} { if ($1>max) max=$1} END {printf "%d\n", max}')00
	local cpuBrandString=$(sysctl -n machdep.cpu.brand_string | tr -d '(TM)' | awk '{print $2, $3}')
	printf "%bGenerating SSDT for Intel $cpuBrandString CPU @ $(bc <<< "scale = 2; $maxTurboFreq / 1000") GHz (max turbo)%b:\n" $gStyleBold $gStyleReset
	echo "$(yes n | "$gRepo/tools/ssdtPRGen.sh/ssdtPRGen.sh" -turbo $maxTurboFreq -x 1 | tail -n 1)"
	cp ~/Library/ssdtPRGen/ssdt.aml "$gEFIMount/EFI/CLOVER/ACPI/patched/SSDT-PR.aml"

	# We're done here, let's prompt the user to reboot
	if [ "$1" -eq 1 ]; then
		printf "\n%bUpdate complete. Do you want to reboot now (y/n)?%b " $gStyleBold $gStyleReset
	else
		printf "\n%bInstallation complete. Do you want to reboot now (y/n)?%b " $gStyleBold $gStyleReset
	fi
	read choice
	case "$choice" in
		y|Y)
			echo "Rebooting..."
			sudo reboot
			;;
		*)
			echo "Exiting..."
			exit 0
			;;
	esac
}

# How many arguments were supplied?
if [ $# -eq 1 ]; then
	# One. Parse it
	case "$1" in
		--install)
			check_macos_version
			check_motherboard
			check_root
			install 0
			;;
		--update)
			git_update > /dev/null
			check_macos_version
			check_motherboard
			check_root
			install 1
			;;
		*)
			usage
			;;
	esac
else
	# Not the right amount. Show help
	help
fi
