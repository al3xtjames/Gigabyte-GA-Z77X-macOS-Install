#!/bin/bash
#
# GA-Z77X OS X Post Installation Script
# Supports Gigabyte GA-Z77X-UD5H & GA-Z77X-UP5 TH
# Gigabyte GA-Z77X DSDT Patch Repo - http://git.io/vIatr

REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

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

check_motherboard()
{
	motherboard=$(tools/bdmesg | grep "Z77X" | cut -d '-' -f2 | strings)
	#printf "Detected Gigabyte GA-Z77X-"$motherboard" motherboard"
	case $motherboard in
		UD5H);;
		'UP5 TH');;
		*)
			echo "ERROR: Motherboard "$board "is unsupported by this script."
			exit 1;;
	esac
}

rehabman_download()
{
	if [ ! -f "${REPO}"/logs/download.log ]; then
		echo "[$(date +"%T")] Script version $VERSION" > "${REPO}"/logs/download.log
	fi

	printf "[$(date +"%T")] " >> "${REPO}"/logs/download.log
	echo "Downloading $2:" | tee -a "${REPO}"/logs/download.log
	curl --location --silent --output /tmp/org.rehabman.download.txt https://bitbucket.org/RehabMan/$1/downloads
	scrape=`grep -o -m 1 href\=\".*$2.*\.zip.*\" /tmp/org.rehabman.download.txt|perl -ne 'print $1 if /href\=\"(.*)\"/'`
	url=https://bitbucket.org$scrape
	printf "[$(date +"%T")] " >> "${REPO}"/logs/download.log
	echo "Location: $url" >> "${REPO}"/logs/download.log
	if [ "$3" == "" ]; then
		curl --remote-name --progress-bar --location "$url"
	else
		curl --output "$3" --progress-bar --location "$url"
	fi
}

check_tools()
{
	cd "${REPO}"/tools

	if [ ! -f bdmesg ]; then
		echo "bdmesg not found."
		echo "Downloading Clover bdmesg:"
		curl --remote-name --progress-bar --location https://transfer.sh/SzMKe/bdmesg
		chmod +x bdmesg
		check_tools
	elif [ ! -f dspci ]; then
		echo "dspci not found."
		echo "Downloading dspci:"
		curl --output dspci.zip --progress-bar --location http://sourceforge.net/projects/dpcimanager/files/latest/download
		unzip dspci.zip > /dev/null
		rm -rf DPCIManager.app
		rm -f dspci.zip
		check_tools
	elif [ ! -f iasl ]; then
		echo "iasl not found."
		rehabman_download acpica iasl iasl.zip
		unzip iasl.zip > /dev/null
		rm -f iasl.zip
		check_tools
	elif [ ! -f patchmatic ]; then
		echo "patchmatic not found."
		rehabman_download os-x-maciasl-patchmatic RehabMan-patchmatic patchmatic.zip
		unzip patchmatic.zip > /dev/null
		rm -f patchmatic.zip
		check_tools
	fi

	cd "${REPO}"
}

decompile_dsdt()
{
	cd "${REPO}"

	echo "[$(date +"%T")] Script version $VERSION" > logs/dsdt_decompile.log
	printf "[$(date +"%T")] " >> logs/dsdt_decompile.log
	echo "Arguments: $REPO/GA-Z77X.sh --decompile-dsdt" >> logs/dsdt_decompile.log

	echo "[$(date +"%T")] patchmatic: extracting ACPI tables from IORegistry" >> logs/dsdt_decompile.log
	echo "[DSDT]: Extracting raw ACPI tables from IORegistry"
	tools/patchmatic -extract
	mv *.aml DSDT/raw/
	printf "[$(date +"%T")] " >> logs/dsdt_decompile.log
	echo "Extraction complete. Output written to $REPO/raw/decompiled." | tee -a logs/dsdt_decompile.log
	echo

	echo "[DSDT]: Decompiling raw ACPI tables"
	tools/iasl -da -dl DSDT/raw/*.aml >> logs/dsdt_decompile.log 2>&1
	printf "[$(date +"%T")] " >> logs/dsdt_decompile.log
	echo "Decompilation complete. Output written to $REPO/DSDT/decompiled." | tee -a logs/dsdt_decompile.log

	rm -f refs.txt
	mv DSDT/raw/*.dsl DSDT/decompiled
	sed -i -e 's,DSDT/raw/DSDT.aml,DSDT.aml,g' DSDT/decompiled/DSDT.dsl
	rm -f DSDT/decompiled/*.dsl-e
}

patch_dsdt()
{
	cd "${REPO}"

	echo "[$(date +"%T")] Script version $VERSION" > logs/dsdt_patch.log
	printf "[$(date +"%T")] " >> logs/dsdt_patch.log
	echo "Arguments: $REPO/GA-Z77X.sh --patch-dsdt" >> logs/dsdt_patch.log

	if [ ! -f $REPO/DSDT/decompiled/DSDT.dsl ]; then
		printf "[$(date +"%T")] " >> logs/dsdt_patch.log
		echo "ERROR: Decompiled DSDT not found! Exiting..." | tee -a logs/dsdt_patch.log
		exit 1
	fi

	echo "[$(date +"%T")] Decompiled DSDT located at $REPO/DSDT/decompiled/DSDT.dsl. Patching..." >> logs/dsdt_patch.log
	echo "[DSDT]: Patching $REPO/DSDT/decompiled/DSDT.dsl..."

	echo "[$(date +"%T")] patchmatic: applying DSDT/patches/$motherboard-main.txt" >> logs/dsdt_patch.log
	echo "[DSDT]: Applying general patch for GA-Z77X-"$motherboard" motherboard"
	printf "[$(date +"%T")] " >> logs/dsdt_patch.log
	tools/patchmatic DSDT/decompiled/DSDT.dsl DSDT/patches/$motherboard-main.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_main.log

	if [[ -z $(tools/dspci | grep "AMD") ]] && [[ -z $(tools/dspci | grep "NVIDIA") ]]; then
		echo "[$(date +"%T")] patchmatic: applying externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000.txt" >> logs/dsdt_patch.log
		echo "[DSDT]: No discrete GPU detected, assuming integrated GPU only"
		echo "[DSDT]: Injecting ig-platform-id into IGPU device for Intel HD Graphics 4000"
		printf "[$(date +"%T")] " >> logs/dsdt_patch.log
		tools/patchmatic DSDT/decompiled/DSDT.dsl externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_Intel-HD-Graphics-4000.log
	else
		echo "[$(date +"%T")] patchmatic: applying externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000-AirPlay.txt" >> logs/dsdt_patch.log
		echo "[DSDT]: Discrete GPU detected, assuming IGPU is for AirPlay Mirroring only"
		echo "[DSDT]: Injecting ig-platform-id into IGPU device for AirPlay Mirroring"
		printf "[$(date +"%T")] " >> logs/dsdt_patch.log
		tools/patchmatic DSDT/decompiled/DSDT.dsl externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000-AirPlay.txt DSDT/decompiled/DSDT.dsl | tee logs/dsdt_patch_Intel-HD-Graphics-4000-AirPlay.log
	fi

	echo "[$(date +"%T")] DSDT patching complete. Output written to $REPO/DSDT/decompiled/DSDT.dsl (will be moved to DSDT/patched)." >> logs/dsdt_patch.log

	mv DSDT/decompiled/*.dsl DSDT/patched

	echo "Patching complete. Output written to $REPO/DSDT/patched."
	echo "Log available at $REPO/logs/dsdt_patch.log."
	echo

	echo "[$(date +"%T")] Script version $VERSION" > logs/dsdt_compile.log
	echo "[$(date +"%T")] Arguments: $REPO/GA-Z77X.sh --patch-dsdt" >> logs/dsdt_compile.log
	echo "[$(date +"%T")] Patched DSDT located at $REPO/DSDT/patched/DSDT.dsl. Compiling..." >> logs/dsdt_compile.log

	echo "[DSDT]: Compiling $REPO/DSDT/patched/DSDT.dsl..."
	tools/iasl DSDT/patched/DSDT.dsl 2>&1 | tee -a logs/dsdt_compile.log | tail -1

	dsdtErrors=$(tail -1 logs/dsdt_compile.log | cut -d ' ' -f 3)
	if [ ! $dsdtErrors = 0 ]; then
		printf "[$(date +"%T")] " >> logs/dsdt_patch.log
		echo "ERROR: DSDT failed to compile! Exiting..." | tee -a logs/dsdt_patch.log
		exit 1
	fi

	mv DSDT/patched/iASL*.aml DSDT/compiled/DSDT.aml
	echo "[$(date +"%T")] DSDT compilation complete. Output written to $REPO/DSDT/patched/DSDT.aml." >> logs/dsdt_compile.log
	echo "Output written to $REPO/DSDT/compiled."
	echo "Log available at $REPO/logs/dsdt_compile.log."

}

inject_hda()
{
	cd "${REPO}"

	echo "[$(date +"%T")] Script version $VERSION" > logs/hda_inject.log
	echo "[$(date +"%T")] Arguments: $REPO/GA-Z77X.sh --inject-hda" >> logs/hda_inject.log

	hexAudioCodec=$(ioreg -rxn IOHDACodecDevice | grep VendorID | awk '{ print $4 }' | sed 's/ffffffff//' | grep '0x10ec\|0x1106')
	decAudioCodec=$(echo $((16#$(echo $hexAudioCodec | sed 's/0x//'))))
	if [[ ! -z $hexAudioCodec ]]; then
		case $decAudioCodec in
			283904153)
				codec="Realtek ALC898";;
			285606977)
				codec="VIA VT2021";;
			*)
				printf "[$(date +"%T")] " >> logs/hda_inject.log
				echo "ERROR: Unsupported audio codec ($hexAudioCodec / $decRealtekCodec)!" | tee -a logs/hda_inject.log
				exit 1;;
		esac
	else
		printf "[$(date +"%T")] " >> logs/hda_inject.log
		echo "ERROR: No audio codec present in IORegistry!" | tee -a logs/hda_inject.log
		exit 1
	fi

	codecShort=$(echo $codec | cut -d ' ' -f 2)
	codecModel=$(echo $codecShort | tr -d '[:alpha:]')

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "$codec ($hexAudioCodec) / ($decAudioCodec) detected." | tee -a logs/hda_inject.log

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Creating injector kext for $codec..." | tee -a logs/hda_inject.log
	mkdir -p audio/$codecShort/AppleHDA$codecModel.kext/Contents/MacOS/

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Creating symbolic link to AppleHDA binary in AppleHDA$codecModel.kext" | tee -a logs/hda_inject.log
	ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA audio/$codecShort/AppleHDA$codecModel.kext/Contents/MacOS/AppleHDA

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Copying patched XML files to AppleHDA$codecModel.kext" | tee -a logs/hda_inject.log
	mkdir audio/$codecShort/AppleHDA$codecModel.kext/Contents/Resources
	cp -R audio/$codecShort/*.zlib audio/$codecShort/AppleHDA$codecModel.kext/Contents/Resources/

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Modifying Info.plist in AppleHDA$codecModel.kext" | tee -a logs/hda_inject.log
	plist=audio/$codecShort/AppleHDA$codecModel.kext/Contents/Info.plist
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
	/usr/libexec/plistbuddy -c "Merge audio/$codecShort/hdacd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Adding binpatches for $codec to config.plist" | tee -a logs/hda_inject.log
	plist=audio/$codecShort/ktp.plist
	cp config-general.plist config.plist
	/usr/libexec/plistbuddy -c "Merge $plist ':KernelAndKextPatches'" config.plist

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Installing created AppleHDA$codecModel.kext" | tee -a logs/hda_inject.log
	echo "NOTE: Root access is required."
	sudo cp -R audio/$codecShort/AppleHDA$codecModel.kext /System/Library/Extensions/
	sudo chmod -R 755 /System/Library/Extensions/AppleHDA$codecModel.kext
	sudo chown -R root:wheel /System/Library/Extensions/AppleHDA$codecModel.kext

	printf "[$(date +"%T")] " >> logs/hda_inject.log
	printf "[HDA]: "
	echo "Rebuilding kext caches" | tee -a logs/hda_inject.log
	sudo kextcache -prelinked-kernel >> logs/hda_inject.log 2>&1
	echo "[$(date +"%T")] Kext installation complete. Installed to /System/Library/Extensions." >> logs/hda_inject.log
	echo "AppleHDA$codecModel.kext installation complete."
	echo "Log available at logs/hda_inject.log"
}

install_clover()
{
	cd "${REPO}"

	echo "[$(date +"%T")] Script version $VERSION" > logs/clover_install.log
	printf "[$(date +"%T")] " >> logs/clover_install.log
	echo "Arguments: $REPO/Inspiron-3x43.sh --install-clover" >> logs/clover_install.log

	mkdir /tmp/io.theracermaster.z77x

	printf "[$(date +"%T")] " >> logs/clover_install.log
	echo "Downloading Clover:" | tee -a logs/clover_install.log
	printf "[$(date +"%T")] " >> logs/clover_install.log
	url=http://sourceforge.net/projects/cloverefiboot/files/latest/download
	echo "Location: $url" >> logs/clover_install.log
	curl --output /tmp/io.theracermaster.z77x/clover.zip --progress-bar --location $url
	cd /tmp/io.theracermaster.z77x/
	unzip clover.zip > /dev/null
	rm -f clover.zip

	if [ ! -f Clover*.pkg ]; then
		printf "[$(date +"%T")] " >> logs/clover_install.log
		echo "ERROR: Clover failed to download!" | tee -a logs/clover_install.log
		exit 1
	fi

	pkgmd5=$(md5 Clover*.pkg | cut -d ' ' -f4)
	md5=$(cat Clover*.pkg.md5 | cut -d ' ' -f4)
	if [ ! $pkgmd5 = $md5 ]; then
		printf "[$(date +"%T")] " >> logs/clover_install.log
		echo "ERROR: Downloaded Clover package has invalid checksum!" | tee -a logs/clover_install.log
		exit 1
	fi

	pkgutil --expand Clover*.pkg packages/
	cd packages/EFIFolder.pkg
	cat Payload | gzip --quiet -d - | cpio -id --quiet

	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	osVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)
	efiVolume=$(diskutil list "$osVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')
	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) mounted at $mountPoint." | tee -a "${REPO}"/logs/clover_install.log
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) is already mounted at $mountPoint." | tee -a "${REPO}"/logs/clover_install.log
	fi

	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	printf "[EFI]: "
	echo "Installing Clover to the EFI partition" | tee -a "${REPO}"/logs/clover_install.log
	mv EFI "$mountPoint"
	mkdir "$mountPoint/EFI/CLOVER/drivers64uefi"
	cd ..

	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	printf "[EFI]: "
	echo "Installing Clover UEFI Drivers" | tee -a "${REPO}"/logs/clover_install.log
	cd FSInject-64.UEFI.pkg
	cat Payload | gzip --quiet -d - | cpio -id --quiet
	mv FSInject-64.efi "$mountPoint/EFI/CLOVER/drivers64uefi"
	cd ..
	cd OsxAptioFix2Drv-64.pkg
	cat Payload | gzip --quiet - | cpio -id --quiet
	mv OsxAptioFix2Drv-64.efi "$mountPoint/EFI/CLOVER/drivers64uefi"
	cd "$mountPoint/EFI/CLOVER"
	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	echo "Downloading HFSPlus.efi:" | tee -a "${REPO}"/logs/clover_install.log
	url=https://github.com/JrCs/CloverGrowerPro/blob/master/Files/HFSPlus/X64/HFSPlus.efi?raw=true
	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	echo "Location: $url" >> "${REPO}"/logs/clover_install.log
	curl --output drivers64uefi/HFSPlus.efi --progress-bar --location $url
	mv "${REPO}"/config.plist "$mountPoint/EFI/CLOVER"

	printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
	printf "[EFI]: "
	echo "Installing kexts to EFI partition" | tee -a "${REPO}"/logs/clover_install.log
	mkdir -p "$mountPoint/EFI/CLOVER/kexts/Other"
	rehabman_download os-x-fakesmc-kozlek RehabMan-FakeSMC /tmp/FakeSMC.zip
	cd /tmp/
	unzip /tmp/FakeSMC.zip > /dev/null
	mv /tmp/FakeSMC.kext "$mountPoint/EFI/CLOVER/kexts/Other"
	mkdir "$mountPoint/EFI/CLOVER/kexts/Other/FakeSMC.kext/Contents/PlugIns"
	mv /tmp/FakeSMC_CPUSensors.kext "$mountPoint/EFI/CLOVER/kexts/Other/FakeSMC.kext/Contents/PlugIns/CPUSensors.kext"
	mv /tmp/FakeSMC_GPUSensors.kext "$mountPoint/EFI/CLOVER/kexts/Other/FakeSMC.kext/Contents/PlugIns/GPUSensors.kext"
	mv /tmp/FakeSMC_LPCSensors.kext "$mountPoint/EFI/CLOVER/kexts/Other/FakeSMC.kext/Contents/PlugIns/LPCSensors.kext"
	if [[ ! -z $("${REPO}"/tools/dspci | grep "8086:1503") ]] && [[ ! -z $("${REPO}"/tools/dspci | grep "1969:1091") ]]; then
		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		printf "[EFI]: "
		echo "Detected Intel 82579V GBe & Qualcomm Atheros AR8161 GBe." | tee -a "${REPO}"/logs/clover_install.log

		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Downloading IntelMausiEthernet.kext" | tee -a "${REPO}"/logs/clover_install.log
		url=https://transfer.sh/yJXVk/intelmausiethernet.kext.zip
		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Location: $url" >> "${REPO}"/logs/clover_install.log
		curl --output /tmp/IntelMausiEthernet.zip --progress-bar --location $url
		unzip /tmp/IntelMausiEthernet.zip > /dev/null
		mv /tmp/IntelMausiEthernet.kext "$mountPoint/EFI/CLOVER/kexts/Other"

		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Downloading AtherosE2200Ethernet.kext" | tee -a "${REPO}"/logs/clover_install.log
		url=https://transfer.sh/Jucn9/atherose2200ethernet.kext.zip
		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Location: $url" >> "${REPO}"/logs/clover_install.log
		curl --output /tmp/AtherosE2200Ethernet.zip --progress-bar --location $url
		unzip /tmp/AtherosE2200Ethernet.zip > /dev/null
		mv /tmp/AtherosE2200Ethernet.kext "$mountPoint/EFI/CLOVER/kexts/Other"
	elif [[ ! -z $("${REPO}"/tools/dspci | grep "8086:1503") ]]; then
		printf "[$(date +"%T")] " >> logs/clover_install.log
		printf "[EFI]: "
		echo "Detected Intel 82579V GBe." | tee -a logs/clover_install.log

		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Downloading IntelMausiEthernet.kext" | tee -a "${REPO}"/logs/clover_install.log
		url=https://transfer.sh/yJXVk/intelmausiethernet.kext.zip
		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Location: $url" >> "${REPO}"/logs/clover_install.log
		curl --output /tmp/IntelMausiEthernet.zip --progress-bar --location $url
		unzip /tmp/IntelMausiEthernet.zip > /dev/null
		mv /tmp/IntelMausiEthernet.kext "$mountPoint/EFI/CLOVER/kexts/Other"
	elif [[ ! -z $("${REPO}"/tools/dspci | grep "1969:1091") ]]; then
		printf "[$(date +"%T")] " >> logs/clover_install.log
		printf "[EFI]: "
		echo "Detected Qualcomm Atheros AR8161 GBe." | tee -a logs/clover_install.log

		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Downloading AtherosE2200Ethernet.kext" | tee -a "${REPO}"/logs/clover_install.log
		url=https://transfer.sh/Jucn9/atherose2200ethernet.kext.zip
		printf "[$(date +"%T")] " >> "${REPO}"/logs/clover_install.log
		echo "Location: $url" >> "${REPO}"/logs/clover_install.log
		curl --output /tmp/AtherosE2200Ethernet.zip --progress-bar --location $url
		unzip /tmp/AtherosE2200Ethernet.zip > /dev/null
		mv /tmp/AtherosE2200Ethernet.kext "$mountPoint/EFI/CLOVER/kexts/Other"
	fi

	cd "${REPO}"

	printf "[$(date +"%T")] " >> logs/clover_install.log
	printf "[EFI]: "
	echo "Generating serial number, MLB & SmUUID for Clover SMBIOS" | tee -a logs/clover_install.log
	chmod +x externals/simpleMacSerial/simpleMacSerial.sh
	chmod +x externals/simpleMLB/simpleMLB.sh
	serialNumber=$(externals/simpleMacSerial/simpleMacSerial.sh iMac13,1)
	MLB=$(externals/simpleMLB/simpleMLB.sh $serialNumber)
	SmUUID=$(uuidgen)
	printf "[$(date +"%T")] " >> logs/clover_install.log
	echo "simpleMacSerial: generated $serialNumber" | tee -a logs/clover_install.log
	printf "[$(date +"%T")] " >> logs/clover_install.log
	echo "simpleMLB: generated $MLB" | tee -a logs/clover_install.log
	printf "[$(date +"%T")] " >> logs/clover_install.log
	echo "uuidgen: generated $SmUUID" | tee -a logs/clover_install.log
	plist="$mountPoint/EFI/CLOVER/config.plist"
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SerialNumber '$serialNumber'" $plist
	/usr/libexec/plistbuddy -c "Set :RtVariables:MLB '$MLB'" $plist
	/usr/libexec/plistbuddy -c "Set :SMBIOS:SmUUID '$SmUUID'" $plist

	printf "[$(date +"%T")] " >> logs/clover_install.log
	printf "[EFI]: "
	echo "Copying patched DSDT to EFI partition" | tee -a logs/clover_install.log
	cp DSDT/compiled/*.aml "$mountPoint/EFI/CLOVER/ACPI/patched"

	rm -rf /tmp/*.zip
	rm -rf /tmp/io.theracermaster.z77x/
}

cleanup()
{
	cd "${REPO}"

	printf "Deleting generated files in repo folders..."
	rm -rf audio/*/*.kext
	rm -f config.plist
	rm -f DSDT/compiled/*.aml
	rm -f DSDT/decompiled/*.dsl
	rm -f DSDT/patched/*.dsl
	rm -f DSDT/raw/*.aml
	rm -f logs/*.log
	rm -f /tmp/*.zip
	echo "complete."
}

RETVAL=0

case "$1" in
	--update)
		git_update
		RETVAL=1;;
	--decompile-dsdt)
		check_tools
		decompile_dsdt
		RETVAL=1;;
	--patch-dsdt)
		check_tools
		check_motherboard
		patch_dsdt
		RETVAL=1;;
	--inject-hda)
		check_tools
		check_motherboard
		inject_hda
		RETVAL=1;;
	--install-clover)
		check_tools
		check_motherboard
		install_clover
		RETVAL=1;;
	--cleanup)
		cleanup
		RETVAL=1;;
	*)
		echo "GA-Z77X.sh OS X Post-Installation Script"
		echo "Supports Gigabyte GA-Z77X-UD5H & GA-Z77X-UP5 TH"
		echo "https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
		echo
		echo "Usage: ./GA-Z77X.sh <command>, where <command> is one of the following:"
		echo
		echo "     --update             Update the repo & helper files to the latest version"
		echo "     --decompile-dsdt     Extract and decompile your raw DSDT & SSDTs"
		echo "     --patch-dsdt         Patch the decompiled DSDT & SSDTs"
		echo "     --inject-hda         Install injector kext for your audio codec"
		echo "     --install-clover     Install Clover to the EFI partition"
		echo "     --cleanup            Delete files generated by this script in repo folders"
		echo
		echo "Updates & Info: https://github.com/theracermaster/Gigabyte-GA-Z77X-DSDT-Patch"
esac

exit $RETVAL
