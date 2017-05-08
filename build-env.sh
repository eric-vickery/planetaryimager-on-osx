#!/bin/bash

# This file will make it easier to use the scripts and do stuff on command line
#

function statusBanner
{
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
}

export PLANETARY_IMAGER_DIR=~/PlanetaryImager

if [ -z "${FORCE_BREW_QT}" ]
then
	#NOTE: The user of the Script needs to edit this path to match the system.
	export QT5_DIR=~/Qt/5.7/clang_64
else
	export QT5_DIR=$(brew --prefix qt5)
fi	

export PATH=$(brew --prefix gettext)/bin:${QT5_DIR}/bin:$PATH
export PATH=$(brew --prefix bison)/bin:$PATH
export CMAKE_LIBRARY_PATH=$(brew --prefix gettext)/lib
export CMAKE_INCLUDE_PATH=$(brew --prefix gettext)/include

export QT5DBUS_DIR=$QT5_DIR
export QT5TEST_DIR=$QT5_DIR
export QT5NETWORK_DIR=$QT5_DIR

export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.10
export MACOSX_DEPLOYMENT_TARGET=10.10

echo "PLANETARY_IMAGER_DIR      is [${PLANETARY_IMAGER_DIR}]"

echo "QT5_DIR                   is [${QT5_DIR}]"
echo "PATH                      is [${PATH}]"

echo "CMAKE_LIBRARY_PATH        is [${CMAKE_LIBRARY_PATH}]"
echo "CMAKE_INCLUDE_PATH        is [${CMAKE_INCLUDE_PATH}]"

echo "PATH                      is [${PATH}]"

echo "QT5DBUS_DIR               is [${QT5DBUS_DIR}]"
echo "QT5TEST_DIR               is [${QT5TEST_DIR}]"
echo "QT5NETWORK_DIR            is [${QT5NETWORK_DIR}]"

echo "OSX Deployment target [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
