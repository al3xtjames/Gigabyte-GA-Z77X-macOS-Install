#/bin/bash
#
# GA-Z77X-UD5H Post Installation Script

REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

git_update()
{
	cd ${REPO}
	echo "[GIT]: Updating local data to latest version"
	
	echo "[GIT]: Updating to latest Gigabyte-GA-Z77X-UD5H-DSDT-Patch git master"
	git pull
	
	echo "[GIT]: Initializing Gigabyte-GA-Z77X-Graphics-DSDT-Patch"
	git submodule update --init --recursive
	
	echo "[GIT]: Updating Gigabyte-GA-Z77X-Graphics-DSDT-Patch"
	git submodule foreach git pull origin master
}

extract_dsdt()
{
	installerVolume=$(df / | grep "/dev/disk" | cut -d ' ' -f1)
	efiVolume=$(diskutil list "$installerVolume" | grep EFI | cut -d 'B' -f2 | sed -e 's/^[ \t]*//')

	if [ -z "$(mount | grep $efiVolume | sed -e 's/^[ \t]*//')" ]; then
		diskutil mount "$efiVolume" > /dev/null
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) mounted at $mountPoint."
	else
		mountPoint=$(diskutil info "$efiVolume" | grep "Mount Point" | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
		echo "EFI partition ($efiVolume) is already mounted at $mountPoint."
	fi
	printf "[DSDT]: Decompiling original DSDT from Clover..."
	cd "${REPO}"
	./tools/iasl /$mountPoint/EFI/CLOVER/ACPI/origin/DSDT.aml &> ./logs/dsdt_decompile.log
	echo "complete."
	echo "Decompilation log available at ./logs/dsdt_decompile.log"
	mv /$mountPoint/EFI/CLOVER/ACPI/origin/DSDT.dsl ./DSDT/decompiled/DSDT.dsl
}

patch_dsdt()
{
	echo "Patching DSDT"
	echo "Applying main GA-Z77X-UD5H patch:"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/main.txt ./DSDT/decompiled/DSDT.dsl
	if [[ -z $(system_profiler -detailLevel mini | grep "GeForce") ]] || [[ -z $(system_profiler -detailLevel mini | grep "Radeon") ]]; then
		echo "No discrete GPU detected. Applying Intel HD Graphics 4000 patch:"
		./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000.txt ./DSDT/decompiled/DSDT.dsl
	else
		echo "Discrete GPU detected. Applying Intel HD Graphics 4000 (AirPlay) patch:"
		./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Gigabyte-GA-Z77X-Graphics-DSDT-Patch/Intel-HD-Graphics-4000-AirPlay.txt ./DSDT/decompiled/DSDT.dsl
	fi
	echo "Complete."
}

RETVAL=0

case "$1" in
	--update)
		git_update
		RETVAL=1;;
	--extract-dsdt)
		extract_dsdt
		RETVAL=1;;
	--patch-dsdt)
		patch_dsdt
		RETVAL=1;;
	*) echo "swag";;
esac

exit $RETVAL