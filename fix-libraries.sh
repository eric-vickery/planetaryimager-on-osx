#/bin/bash

# This script has three goals:
# 1) identify programs that use libraries outside of the package (that meet certain criteria)
# 2) copy those libraries to the blah/Frameworks dir
# 3) Update those programs to know where to look for said libraries
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/build-env.sh" > /dev/null

FILES_TO_COPY=()
FRAMEWORKS_DIR="${PLANETARY_IMAGER_APP}/Contents/Frameworks"
#PLUGINS_DIR="${PLANETARY_IMAGER_APP}/Contents/PlugIns"
DRY_RUN_ONLY=""

IGNORED_OTOOL_OUTPUT="/Qt|qt5|${PLANETARY_IMAGER_APP}/|/usr/lib/|/System/"
mkdir -p "${FRAMEWORKS_DIR}"
#mkdir -p "${PLUGINS_DIR}"

function dieUsage
{
    # I really wish that getopt supported the long args.
    #
    echo $*
cat <<EOF
options:
    -d Dry run only (just show what you are going to do)
EOF
exit 9
}

function addFileToCopy
{
	for e in "${FILES_TO_COPY[@]}"
    do 
        if [ "$e" == "$1" ]
        then
            return 0
        fi
    done
	
	FILES_TO_COPY+=($1)
}

function processTarget
{
	target=$1

	entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
    echo "Processing $target"
    
    relativeRoot="${PLANETARY_IMAGER_APP}/Contents"
    
    pathDiff=${target#${relativeRoot}*}

    # Need to calculate the path to the frameworks dir
    #
    if [[ "$pathDiff" == /Frameworks/* ]]
    then
        pathToFrameworks=""
    else        
        pathToFrameworks=$(echo $(dirname "${pathDiff}") | awk -F/ '{for (i = 1; i < NF ; i++) {printf("../")} }')
        pathToFrameworks="${pathToFrameworks}Frameworks/"
    fi
        
	for entry in $entries
	do
		baseEntry=$(basename $entry)
		newname=""

        # The @rpaths need to change to @executable_path
        #
		newname="@loader_path/${pathToFrameworks}${baseEntry}"
		
        echo "    change $entry -> $newname"
        # echo "          install_name_tool -change \\"
        # echo "              $entry \\"
        # echo "              $newname \\"
        # echo "              $target"
        
        if [ -z "${DRY_RUN_ONLY}" ]
        then
            install_name_tool -change \
                $entry \
                $newname \
                $target

        else
            echo "        install_name_tool -change \\"
            echo "            $entry \\"
            echo "            $newname \\"
            echo "            $target"
        fi            

		addFileToCopy "$entry"
	done
    echo ""
    echo "   otool for $target after"
    otool -L $target | egrep -v "$IGNORED_OTOOL_OUTPUT" | awk '{printf("\t%s\n", $0)}'
}

function copyFilesToFrameworks
{
    for libFile in "${FILES_TO_COPY[@]}"
    do
        # if it starts with a / then easy.
        #
        base=$(basename $libFile)

        if [[ $libFile == /* ]]
        then
            filename=$libFile
        else
            # see if I can find it, NOTE:  I had to add the last part and the echo because the find produced multiple results breaking the file copy into frameworks.
            filename=$(echo $(find /usr/local -name "${base}")| cut -d" " -f1)
        fi    

        if [ ! -f "${FRAMEWORKS_DIR}/${base}" ]
        then
        	echo "HAVE TO COPY [$base] from [${filename}] to Frameworks"
            [ -z "${DRY_RUN_ONLY}" ] && cp -L "${filename}" "${FRAMEWORKS_DIR}"
            
            # Seem to need this for the macqtdeploy
            #
            [ -z "${DRY_RUN_ONLY}" ] && chmod +w "${FRAMEWORKS_DIR}/${base}"
        else
            echo ""
        	echo "Skipping Copy: $libFile already in Frameworks "
        fi
    done
}

while getopts "d" option
do
    case $option in
        d)
            DRY_RUN_ONLY="yep"
            ;;
        *)
            dieUsage "Unsupported option $option"
            ;;
    esac
done
shift $((${OPTIND} - 1))

cd ${CRAFT_DIR}

statusBanner "Processing Planetary Imager executable"
processTarget "${PLANETARY_IMAGER_APP}/Contents/MacOS/planetary_imager"

statusBanner "Copying first round of files"
copyFilesToFrameworks

statusBanner "Processing all of the files in the Frameworks dir"

# Then do all of the files in the Frameworks Dir
#
FILES_TO_COPY=()
for file in ${FRAMEWORKS_DIR}/*
do
    base=$(basename $file)
    
	statusBanner "Processing Frameworks file $base"
    processTarget $file
done

statusBanner "Copying eighth round of files for Frameworks"
copyFilesToFrameworks

statusBanner "The following files are now in Frameworks:"
ls -lF ${FRAMEWORKS_DIR}
