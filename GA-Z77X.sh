#/bin/bash
#
# GA-Z77X OS X Post Installation Script
# Gigabyte GA-Z77X DSDT Patch Repo - http://git.io/vIatr

REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

check_motherboard()
{
	motherboard=$(tools/bdmesg | grep "Z77X" | cut -d '-' -f2 | strings)
	printf "Detected Gigabyte GA-Z77X-"$motherboard" motherboard"
	case $motherboard in
		D3H)
			codecName="VIA VT2021"
			codecShortName="VT2021"
			codecModel="2021";;
		UD5H)
			codecName="Realtek ALC898"
			codecShortName="ALC898"
			codecModel="898";;
		*)
			echo "Motherboard "$board "is unsupported by this script."
			exit 0;;
	esac
}

git_update()
{
	cd ${REPO}
	echo "[GIT]: Updating local data to latest version"
	
	echo "[GIT]: Updating to latest Gigabyte-GA-Z77X-DSDT-Patch git master"
	git pull
	
	echo "[GIT]: Initializing Gigabyte-GA-Z77X-Graphics-DSDT-Patch"
	git submodule update --init --recursive
	
	echo "[GIT]: Updating Gigabyte-GA-Z77X-Graphics-DSDT-Patch"
	git submodule foreach git pull origin master
}

decompile_dsdt()
{
	cd "${REPO}"

	echo "[DSDT]: Extracting raw DSDT from IORegistry"
	tools/patchmatic -extract
	mv *.aml DSDT/raw/
	rm *.aml 2&>/dev/null

	printf "[DSDT]: Decompiling raw DSDT..."
	tools/iasl DSDT/raw/DSDT.aml &> logs/dsdt_decompile.log
	echo "complete."
	echo "Decompilation log available at logs/dsdt_decompile.log."
	mv DSDT/raw/DSDT.dsl DSDT/decompiled/DSDT.dsl
}

patch_dsdt()
{
	cd "${REPO}"

	echo "."

	echo "[DSDT]: Applying GA-Z77X-"$motherboard" main patch"
	tools/patchmatic DSDT/decompiled/DSDT.dsl DSDT/patches/$motherboard-main.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_main.log

	if [[ -z $(system_profiler -detailLevel mini | grep "GeForce") ]] && [[ -z $(system_profiler -detailLevel mini | grep "Radeon") ]]; then
		echo "[DSDT]: No discrete GPU detected, assuming integrated GPU only"
		echo "[DSDT]: Applying Intel HD Graphics 4000 patch"
		tools/patchmatic DSDT/decompiled/DSDT.dsl externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_Intel-HD-Graphics-4000.log
	else
		echo "[DSDT]: Discrete GPU detected, assuming both integrated+discrete GPUs"
		echo "[DSDT]: Applying Intel HD Graphics 4000 (AirPlay) patch"
		tools/patchmatic DSDT/decompiled/DSDT.dsl externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000-AirPlay.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_Intel-HD-Graphics-4000-AirPlay.log
	fi

	echo "[DSDT] Compiling patched DSDT"
	tools/iasl DSDT/decompiled/DSDT.dsl | tee logs/dsdt_compile.log
	mv DSDT/decompiled/DSDT.aml DSDT/compiled/DSDT.aml

	echo "Is your CPU overclocked?"
	select yn in "Yes" "No"; do
		case $yn in
			Yes) overclock=true; break;;
			No) overclock=false; break;;
		esac
	done
	chmod +x externals/ssdtPRGen.sh/ssdtPRGen.sh
	if [ "$overclock" == false ]; then
		printf "[DSDT] Generating CPU SSDT for power management (stock frequency)..."
		yes n | externals/ssdtPRGen.sh/ssdtPRGen.sh -c 1 -d 3 -w 2 -x 1 &> logs/SSDT_generate.log

	else
		frequency="$(bdmesg | grep Turbo: | cut -d '/' -f2)00"
		printf "[DSDT] Generating CPU SSDT for power management ("$frequency"MHz turbo frequency)..."
		yes n | externals/ssdtPRGen.sh/ssdtPRGen.sh -c 1 -d 3 -w 2 -x 1 -turbo $frequency &> logs/SSDT_generate.log
	fi
	cp ~/Library/ssdtPRGen/ssdt.aml DSDT/compiled/SSDT.aml
	echo "complete."
}

inject_hda()
{
	cd "${REPO}"

	echo " with "$codecName" audio codec."

	echo "[HDA]: Creating AppleHDA injector kext for "$codecName
	mkdir -p audio/$codecShortName/AppleHDA$codecModel.kext/Contents
	mkdir audio/$codecShortName/AppleHDA$codecModel.kext/Contents/MacOS

	echo "[HDA]: Creating symbolic link to AppleHDA binary in AppleHDA"$codecModel".kext"
	ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA audio/$codecShortName/AppleHDA$codecModel.kext/Contents/MacOS/AppleHDA

	echo "[HDA]: Copying XML files to AppleHDA"$codecModel".kext"
	mkdir audio/$codecShortName/AppleHDA$codecModel.kext/Contents/Resources
	cp -R audio/$codecShortName/*.zlib audio/$codecShortName/AppleHDA$codecModel.kext/Contents/Resources/

	echo "[HDA]: Modifying Info.plist in AppleHDA"$codecModel".kext"
	plist=audio/$codecShortName/AppleHDA$codecModel.kext/Contents/Info.plist
	cp /System/Library/Extensions/AppleHDA.kext/Contents/Info.plist $plist
	replace=`/usr/libexec/plistbuddy -c "Print :NSHumanReadableCopyright" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :NSHumanReadableCopyright '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleGetInfoString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleGetInfoString '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleVersion" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleVersion '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleShortVersionString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleShortVersionString '$replace'" $plist
	/usr/libexec/plistbuddy -c "Add ':HardwareConfigDriver_Temp' dict" $plist
	/usr/libexec/plistbuddy -c "Merge /System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist ':HardwareConfigDriver_Temp'" $plist
	/usr/libexec/plistbuddy -c "Copy ':HardwareConfigDriver_Temp:IOKitPersonalities:HDA Hardware Config Resource' ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
	/usr/libexec/plistbuddy -c "Delete ':HardwareConfigDriver_Temp'" $plist
	/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $plist
	/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $plist
	/usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $plist
	/usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
	/usr/libexec/plistbuddy -c "Merge audio/$codecShortName/hdacd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist

	echo "[HDA]: Installing created AppleHDA"$codecModel".kext"
	echo "NOTE: Root access is required."
	sudo cp -R audio/$codecShortName/AppleHDA$codecModel.kext /System/Library/Extensions

	printf "[HDA]: Rebuilding kext caches..."
	sudo kextcache -prelinked-kernel &> logs/hda_kextcache.log
	echo "complete."
}

install_clover()
{
	cd "${REPO}"

	echo "."

	osVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)
	efiVolume=$(diskutil list "$osVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')
	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) mounted at $mountPoint."
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) is already mounted at $mountPoint."
	fi

	echo "[EFI]: Installing Clover to EFI partition"
	mkdir -p /Volumes/EFI/EFI/CLOVER/ACPI/patched/
	cp -R EFI/BOOT/ /Volumes/EFI/EFI/BOOT/
	cp -R EFI/CLOVER/ /Volumes/EFI/EFI/CLOVER/
	mv /Volumes/EFI/EFI/CLOVER/$motherboard-kexts /Volumes/EFI/EFI/CLOVER/kexts
	rm -rf /Volumes/EFI/EFI/CLOVER/*-kexts
	mv /Volumes/EFI/EFI/CLOVER/$motherboard-config.plist /Volumes/EFI/EFI/CLOVER/config.plist
	rm /Volumes/EFI/EFI/CLOVER/*-config.plist

	echo "[EFI]: Generating serial number, MLB & SmUUID for Clover SMBIOS"
	chmod +x externals/simpleMacSerial/simpleMacSerial.sh
	chmod +x externals/simpleMLB/simpleMLB.sh
	serialNumber=$(externals/simpleMacSerial/simpleMacSerial.sh iMac13,1)
	MLB=$(externals/simpleMLB/simpleMLB.sh $serialNumber)
	SmUUID=$(uuidgen)
	plist=/Volumes/EFI/EFI/CLOVER/config.plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" $plist
	/usr/libexec/plistbuddy -c "Set :RtVariables:MLB '$MLB'" $plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SmUUID '$SmUUID'" $plist

	echo "[EFI]: Copying patched DSDT to EFI partition"
	cp -R DSDT/compiled/DSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched/DSDT.aml

	printf "[EFI]: Copying generated SSDT to EFI partition..."
	cp -R DSDT/compiled/SSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched/SSDT.aml
	echo "complete."
}

cleanup()
{
	cd "${REPO}"
	printf "Deleting generated files in repo folders..."
	rm -rf audio/*/*.kext 2&>/dev/null
	rm DSDT/compiled/*.aml 2&>/dev/null
	rm DSDT/decompiled/*.dsl 2&>/dev/null
	rm DSDT/raw/*.aml 2&>/dev/null
	rm logs/*.log 2&>/dev/null
	echo "complete."
}

RETVAL=0

case "$1" in
	--update)
		git_update
		RETVAL=1;;
	--decompile-dsdt)
		decompile_dsdt
		RETVAL=1;;
	--patch-dsdt)
		check_motherboard
		patch_dsdt
		RETVAL=1;;
	--inject-hda)
		check_motherboard
		inject_hda
		RETVAL=1;;
	--install-clover)
		check_motherboard
		install_clover
		RETVAL=1;;
	--cleanup)
		cleanup
		RETVAL=1;;
	*)
		echo "Gigabyte GA-Z77X DSDT Patcher & Post Install Script"
		echo "https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
		echo
		echo "--update: Update to latest git version (including externals)"
		echo "--decompile-dsdt: Decompile DSDT files from Clover on OS X Installation USB or DSDT/raw to DSDT/decompiled"
		echo "--patch-dsdt: Patch DSDT files in DSDT/decompiled with motherboard-specific patches, compile them to DSDT/compiled, and generate a processor SSDT"
		echo "--inject-hda: Create AppleHDA injector kext based off motherboard codec"
		echo "--install-clover: Install Clover EFI bootloader to system EFI partition"
		echo "--cleanup: Deletes all files generated by this script in the repo folders"
		echo
		echo "Credits:"
		echo "Portions of the main motherboard DSDT patches: http://maciasl.sourceforge.net/pjalm/gigabyte"
		echo "Portions of the main motherboard DSDT patches: https://github.com/RehabMan/Laptop-DSDT-Patch"
		echo "Intel HD Graphics 4000 AirPlay DSDT patches: http://www.tonymacx86.com/graphics/118662-amd-nvidia-primary-display-airplay-mirroring.html"
		echo "patchmatic: https://github.com/RehabMan/OS-X-MaciASL-patchmatic"
		echo "ssdtPRgen: https://github.com/Piker-Alpha/ssdtPRGen.sh"
		echo "Realtek ALC898 files: https://github.com/toleda/audio_ALC898"
		echo "VIA VT2021 files: http://www.hackintoshosx.com/files/file/4237-10103-applehda-for-vt2021"
		echo "Clover EFI bootloader: https://github.com/Clover-EFI-Bootloader/clover"
		echo "AtheroE2200Ethernet: https://github.com/Mieze/AtherosE2200Ethernet"
		echo "FakeSMC kozlek (RehabMan fork): https://github.com/RehabMan/OS-X-FakeSMC-kozlek"
		echo "IntelMausiEthernet: https://github.com/Mieze/IntelMausiEthernet"
		echo "Portions of this script and repo design: https://github.com/AustinSMU/PRECISION-M3800-OSX"
esac

exit $RETVAL