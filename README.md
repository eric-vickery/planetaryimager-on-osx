## Instructions for installing PlanetaryImager and a QT Creator Project on OS X with options for creating a disk image. 

This script is built on:

	-the work that jamiesmith did to automate building kstars on OS X


Prerequisites for running the script include:

### Installing Xcode and accept the license agreements

[Apple Developer Site](developer.apple.com/download/) or from the 
[app store](https://itunes.apple.com/us/app/xcode/id497799835)

### Installing Homebrew

`/usr/bin/ruby -e "$(curl -fsSL raw.githubusercontent.com/Homebrew/install/master/install)"`

### Installing QT

Either install QT via a download from: [QT.io](www.qt.io/download-open-source/) or via homebrew.
Both methods should work, but the homebrew method could take HOURS.  If you do the homebrew method, 
then be sure to install qt with dbus.  Note that the install from qt sometimes takes
a long time too, and the installer appears to become unresponsive before
it starts copying stuff.  I used the offline file, but you can use either.  

Note: For now, you should use a version of QT 5.7, because I have not tested 5.8 so there is no guarantee 5.8 would work.


### Downloading the files from this repo 

```console
	mkdir -p ~/Projects
	cd ~/Projects/
	
	# if you don't already have the repo:
	# 
	git clone https://github.com/eric-vickery/planetaryimager-on-osx.git
	
	# if you do already have it:
	# (if you changed something then you will have to work that out)
	cd ~/Projects/planetaryimager-on-osx
	git pull
```

### Editing the build-env.sh file to reflect your version of QT

Edit this line:  export QT5_DIR=~/Qt/5.7/clang_64
To reflect the path to your QT_5 installation.

### Running the Script
```console
	# Change to the script directory
	cd ~/Projects/planetaryimager-on-osx
	# If you want to build a full PlanetaryImager app, QT Creator project and dmg, then do:
	./build-planetaryimager.sh -acp
	# If you want to build a QT Creator Project you can work on and a full PlanetaryImager app, instead do:
	./build-kstars.sh -ac
```

Note that the -a option announces key installation steps audibly, the -c option creates and builds a Qt Creator Project and the -p option will create the dmg that can easily be distributed.

After the script finishes, whichever method you chose, you should have built a PlanetaryImager app that can actually be used.

	-If you chose the app and dmg option, you can now distribute the app and/or dmg to other people freely.  The dmg has associated md5 and sha256 files for download verification.

	-If you chose the QT Creator option, you should follow the EditingPlanetaryImagerInQTCreatorOnOSX.pdf document to get all set up to do your editing.

If you want to edit the code you must have QT Creator installed on your system.

Now you should be all set up!!!

One note on distribution:  Due to our usage of homebrew in building the dependencies of PlanetaryImager, the app/dmg that is build with this script will only work on installations of OS X equal to or greater than your version.  Anotherwords, you cannot build an app bundle on Sierra and expect it to work perfectly on Yosemite.  This is because homebrew ignores the deployment target flag in its installs.  We may address this in the future.
