#!/bin/bash

# This script is fashioned after the script in the project github.com/jamiesmith/kstars-on-osx.git

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/build-env.sh"

PLANETARY_IMAGER_GIT="https://github.com/GuLinux/PlanetaryImager.git"

ANNOUNCE=""
BUILD_PLANETARY_IMAGER_CMAKE=""
PACKAGING_PLANETARY_IMAGER=""
DRY_RUN_ONLY=""
FORCE_RUN=""
SKIP_BREW=""
export PLANETARY_IMAGER_APP="${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.app"

function processOptions
{
	while getopts "acdfps" option
	do
	    case $option in
	        a)
	            ANNOUNCE="Yep"
	            ;;
	        c)
	            BUILD_PLANETARY_IMAGER_CMAKE="Yep"
	            ;;
	        d)
	            DRY_RUN_ONLY="Yep"
	            ;;
	        f)
	            FORCE_RUN="Yep"
	            ;;
	        p)
	            PACKAGING_PLANETARY_IMAGER="Yep"
	            ;;
	        s)
	            SKIP_BREW="Yep"
	            ;;
	        *)
	            dieUsage "Unsupported option $option"
	            ;;
	    esac
	done
	shift $((${OPTIND} - 1))

	echo ""
	echo "ANNOUNCE            = ${ANNOUNCE:-Nope}"
	echo "BUILD_PLANETARY_IMAGER_CMAKE  = ${BUILD_PLANETARY_IMAGER_CMAKE:-Nope}"
	echo "PACKAGING_PLANETARY_IMAGER    = ${PACKAGING_PLANETARY_IMAGER:-Nope}"
}

function usage
{
    # I really wish that getopt supported the long args.
    #

cat <<EOF
	options:
	    -a Announce stuff as you go
	    -c Build kstars via cmake (ONLY one of -c , -x, or -e can be used)
	    -d Dry run only (just show what you are going to do)
	    -f Force build even if there are script updates
	    -s Skip brew (only use this if you know you already have them)
    
	To build a complete cmake build you would do:
	    $0 -ac
    
	To build a complete cmake build and package to a disk image you would do:
	    $0 -acp
EOF
}

function dieUsage
{
	echo ""
    echo $*
	echo ""
	usage
	exit 9
}

function dieError
{
	echo ""
    echo $*
	echo ""
	exit 9
}

function exitEarly
{
    announce "$*"
    trap - EXIT
    exit 0
}

function announce
{
    [ -n "$ANNOUNCE" ] && say -v Daniel "$*"
    statusBanner "$*"
}

function brewInstallIfNeeded
{
    brew ls $1 > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Installing : $*"
        brew install $*
    else
        echo "brew : $* is already installed"
    fi
}

function scriptDied
{
    announce "Something failed"
}

function checkForConnections
{
	git ls-remote PLANETARY_IMAGER_GIT &> /dev/null
	statusBanner "Git Respository found"
}

function checkForQT
{
	if [ -z "$QT5_DIR" ]
	then
		dieUsage "Cannot proceed, qt not installed - see the readme."
	fi
}

function installBrewDependencies
{
    announce "Installing brew dependencies"

	# NOTE: Uncommect out these lines if you don't already have git adn/or Qt installed'
    # brewInstallIfNeeded git
    # brewInstallIfNeeded qt5

    brewInstallIfNeeded cmake
    brewInstallIfNeeded boost
    brewInstallIfNeeded cfitsio
	brewInstallIfNeeded ccfits 
	brewInstallIfNeeded opencv3
}

function buildPlanetaryImager
{
	mkdir -p ${PLANETARY_IMAGER_DIR}
	
    announce "Building Planetary Imager"
    cd ${PLANETARY_IMAGER_DIR}/

	if [ -d "${PLANETARY_IMAGER_DIR}/PlanetaryImager" ]
	then
		cd ${PLANETARY_IMAGER_DIR}/PlanetaryImager
		git pull
		cd ..
	else
		git clone --recursive ${PLANETARY_IMAGER_GIT}
	fi

    mkdir -p build
    cd build

	cmake ../PlanetaryImager -DCMAKE_PREFIX_PATH=${QT5_DIR}
	make all
}

function bundlePlanetaryImager
{
	# mkdir ${PLANETARY_IMAGER_DIR}/App
	# mkdir ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App
	# mkdir ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents
	mkdir -p ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents/MacOS
	mkdir -p ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents/Resources

	cp ${DIR}/info.plist ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents
	cp ${PLANETARY_IMAGER_DIR}/build/src/planetary_imager ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents/MacOS
	cp ${PLANETARY_IMAGER_DIR}/PlanetaryImager/files/planetary_imager.icns ${PLANETARY_IMAGER_DIR}/App/PlanetaryImager.App/Contents/Resources
	
    # announce "Fixing the directory names and such"
    ${DIR}/fix-libraries.sh

    cd ${PLANETARY_IMAGER_DIR}/App
    macdeployqt PlanetaryImager.app -executable=${PLANETARY_IMAGER_APP}/Contents/MacOS/planetary_imager
}

function packagePlanetaryImager
{
    set +e

    announce "Building disk image"
    cd ${PLANETARY_IMAGER_DIR}/App

   	#Setting up some short paths
    UNCOMPRESSED_DMG=${PLANETARY_IMAGER_DIR}/App/PlanetaryImagerUncompressed.dmg
    
	#Create and attach DMG
    hdiutil create -srcfolder ${PLANETARY_IMAGER_APP}/../ -size 190m -fs HFS+ -format UDRW -volname PlanetaryImager ${UNCOMPRESSED_DMG}
    hdiutil attach ${UNCOMPRESSED_DMG}
    
    # Obtain device information
	DEVS=$(hdiutil attach ${UNCOMPRESSED_DMG} | cut -f 1)
	DEV=$(echo $DEVS | cut -f 1 -d ' ')
	VOLUME=$(mount |grep ${DEV} | cut -f 3 -d ' ')
	
	# copy in and set volume icon
	# cp ${DIR}/DMGIcon.icns ${VOLUME}/DMGIcon.icns
	# mv ${VOLUME}/DMGIcon.icns ${VOLUME}/.VolumeIcon.icns
	# SetFile -c icnC ${VOLUME}/.VolumeIcon.icns
	# SetFile -a C ${VOLUME}

	# copy in background image
	# mkdir -p ${VOLUME}/Pictures
	# cp ${PLANETARY_IMAGER_DIR}/PlanetaryImager/files/background.png ${VOLUME}/Pictures/background.jpg
	
	# symlink Applications folder, arrange icons, set background image, set folder attributes, hide pictures folder
	ln -s /Applications/ ${VOLUME}/Applications
	set_bundle_display_options ${VOLUME}
	# mv ${VOLUME}/Pictures ${VOLUME}/.Pictures
 
	# Unmount the disk image
	hdiutil detach $DEV
 
	# Convert the disk image to read-only
	hdiutil convert ${UNCOMPRESSED_DMG} -format UDBZ -o ${PLANETARY_IMAGER_DIR}/App/planetary-imager-latest.dmg
	
	# Remove the Read Write DMG
	rm ${UNCOMPRESSED_DMG}
	
	# Generate Checksums
	md5 ${PLANETARY_IMAGER_DIR}/App/planetary-imager-latest.dmg > ${PLANETARY_IMAGER_DIR}/App/planetary-imager-latest.md5
	shasum -a 256 ${PLANETARY_IMAGER_DIR}/App/planetary-imager-latest.dmg > ${PLANETARY_IMAGER_DIR}/App/planetary-imager-latest.sha256
}

function checkUpToDate
{	
	cd "$DIR"

	localVersion=$(git log --pretty=%H ...refs/heads/master^ | head -n 1)
	remoteVersion=$(git ls-remote origin -h refs/heads/master | cut -f1)
	cd - > /dev/null
	echo ""
	echo ""

	if [ "${localVersion}" != "${remoteVersion}" ]
	then

		if [ -z "$FORCE_RUN" ]
		then
			announce "Script is out of date"
			echo ""
			echo "override with a -f"
			echo ""
			echo "There is a newer version of the script available, please update - run"
			echo "cd $DIR ; git pull"

			echo "Aborting run"
			exit 9
		else
			echo "WARNING: Script is out of date"
			
			echo "Forcing run"
		fi
	else
		echo "Script is up-to-date"
		echo ""
	fi	
}

function set_bundle_display_options() {
	osascript <<-EOF
		tell application "Finder"
			set f to POSIX file ("${1}" as string) as alias
			tell folder f
				open
				tell container window
					set toolbar visible to false
					set statusbar visible to false
					set current view to icon view
					delay 1 -- sync
					set the bounds to {20, 50, 300, 400}
				end tell
				delay 1 -- sync
				set icon size of the icon view options of container window to 64
				set arrangement of the icon view options of container window to not arranged
				set position of item "QuickStart.pdf" to {100, 50}
				set position of item "CopyrightInfoAndSourcecode.pdf" to {100, 150}
				set position of item "Applications" to {340, 50}
				set position of item "KStars.app" to {340, 150}
				set background picture of the icon view options of container window to file "background.jpg" of folder "Pictures"
				set the bounds of the container window to {0, 0, 440, 270}
				update without registering applications
				delay 5 -- sync
				close
			end tell
			delay 5 -- sync
		end tell
	EOF
 }

##########################################
# This is where the bulk of it starts!
#

# Before anything, check for QT and to see if the remote servers are accessible
#
checkForQT
checkForConnections

processOptions $@

#checkUpToDate

if [ -z "$SKIP_BREW" ]
then
    installBrewDependencies
else
    announce "Skipping brew dependencies"
fi

# if [ -n "${BUILD_PLANETARY_IMAGER_CMAKE}" ] && [ -d "${PLANETARY_IMAGER_DIR}/build" ]
# then
# 	rm -Rf ${PLANETARY_IMAGER_DIR}/build
# fi

[ -n "${DRY_RUN_ONLY}" ] && exitEarly "Dry Run Only"

# From here on out exit if there is a failure
#
set -e
trap scriptDied EXIT

if [ -n "${BUILD_PLANETARY_IMAGER_CMAKE}" ]
then
    buildPlanetaryImager
else
    announce "Not building planetery imager"
fi

announce "Bundling Planetary Imager"
bundlePlanetaryImager

if [ -n "${PACKAGING_PLANETARY_IMAGER}" ]
then
	packagePlanetaryImager
fi

# Finally, remove the trap
trap - EXIT
announce "Script execution complete"
