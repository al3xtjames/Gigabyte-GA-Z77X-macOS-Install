#!/usr/bin/env zsh
#
# common.sh - Common functions for macOS post-installation scripts
# By theracermaster - https://github.com/theracermaster

## The user ID
gID=$(id -u)

## The major version of macOS
gOSVersion=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

## The location where the EFI partition is mounted, will be properly initialized later
gEFIMount="Unknown"

## iasl binary
IASL="$gRepo/tools/iasl"

## Styling
STYLE_RESET="\e[0m"
STYLE_BOLD="\e[1m"
STYLE_UNDERLINED="\e[4m"

## Colors
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

# Prints an error message and exits.
function _printError()
{
	# Print the error text and exit
	string="${COLOR_RED}${STYLE_BOLD}ERROR: ${STYLE_RESET}${STYLE_BOLD}$1${STYLE_RESET} Exiting..."
	printf "%s\n" "$string"

	exit 1
}

# Checks if the current user is root.
function _checkRoot()
{
	if [ "$gID" -ne 0 ]; then
		# Re-run the script as root
		printf "This part of the script ${STYLE_UNDERLINED}needs${STYLE_RESET} to be run as root.\n"

		sudo clear
	fi
}

# Mounts the EFI system partition for the currently-booted disk.
function _mountEFI()
{
	# Find the BSD device name for the current OS disk
	osVolume=$(df / | awk '/disk/ {print $1}')

	# Find the EFI partition of the disk from the OS disk
	efiVolume=$(diskutil list "$osVolume" | awk '/EFI/ {print $6}')

	# Make sure the EFI partition actually exists
	if [ -z "$efiVolume" ]; then
		## Check if the OS is installed on a Core Storage (CS) logical volume
		csVolume=$(diskutil info "$osVolume" | grep "Core Storage")
		if [ ! -z "$csVolume" ]; then ## CS volume detected
			## We can find the recovery volume in the diskutil output, and then use that to find the EFI partition
			recoveryVolume=$(diskutil info "$osVolume" | awk '/Recovery Disk:/ {print $3}')
			efiVolume=$(diskutil list "$recoveryVolume" | awk '/EFI/ {print $6}')
		else ## No CS volume present, so assume no EFI partition
			printError "No EFI partition present on OS volume ($osVolume)!"
		fi
	fi

	# Check if the EFI partition is already mounted; if not, mount it
	if [ -z "$(mount | awk '/'"$efiVolume"'/ {print $1}')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		gEFIMount=$(diskutil info "$efiVolume" | awk '/Mount Point/ {print $3}')
		echo "EFI system partition ($efiVolume) mounted at $gEFIMount."
	else
		gEFIMount=$(diskutil info "$efiVolume" | awk '/Mount Point/ {print $3}')
		echo "EFI system partition ($efiVolume) is already mounted at $gEFIMount."
	fi
}

# Installs a kext to the Extensions directory for the currently-booted disk.
function _installKext()
{
	# Fix the permissions of the kext
	sudo chmod -R 755 "$1"
	sudo chown -R 0:0 "$1"

	# Copy the kext to the proper extensions folder
	if [ $gOSXVersion -e 10.11 ]; then
		sudo mv "$1" /Library/Extensions
	else
		sudo mv "$1" /System/Library/Extensions
	fi
}

# Installs a kext to the Clover kexts directory for the currently-booted disk.
function _installKextEFI()
{
	# Copy the kext to the Clover kexts folder on the EFI partition
	cp -R "$1" "$gEFIMount/EFI/CLOVER/kexts/Other"
}

# Looks for a device in the IORegistry.
function _checkDevicePresence()
{
	ioreg -k compatible -p IODeviceTree | grep compatible | grep "pci$1,$2"
}

# Generates SMBIOS data for config.plist.
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

	serialNumber=$("$gRepo/modules/MacGen/simpleMacSerial.sh" $gProductName)
	MLB=$("$gRepo/modules/MacGen/simpleMLBSerial.sh" $gProductName $serialNumber)
	smUUID=$(uuidgen)

	echo " - Product Name: $gProductName"
	echo " - Serial Number: $serialNumber"
	echo " - MLB Serial Number: $MLB"
	echo " - System UUID: $smUUID"

	# Copy the generated data to the plist
	/usr/libexec/PlistBuddy -c "Set :SMBIOS:ProductName '$gProductName'" "$plist"
	/usr/libexec/PlistBuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" "$plist"
	/usr/libexec/PlistBuddy -c "Set :RtVariables:MLB '$MLB'" "$plist"
	/usr/libexec/PlistBuddy -c "Set :SMBIOS:SmUUID '$smUUID'" "$plist"
}
