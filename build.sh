#!/usr/bin/env bash

set -u

show_usage() {
    cat << EOF
Usage ${0} -w <workspace> -r <rom> -b <branch>

Options:
  -w,--workspace  Path to workspace
  -r,--rom        The ROM to build
  -b,--branch     The ROM's git branch to build
  -d,--device     The device to build for
  -o,--romopts    ROM-specific options (in form: param1=value1,param2=value2)
  -s,--sync       Run \"repo sync\" before building
  -c,--clean      Clean up tree before building
  -u,--updatecl   Update changelog timestamp if build succeeds
  --listroms      List ROMs this script can build
  --listromopts   List options the ROM script accepts
  --sourcedir     Path to ROM's source code (optional)

Directories:
  If '-d' is not set, the source code will be placed in a subdirectory of the
  workspace named <rom>_<branch>.

  The workspace will contain a directory named 'archive' that holds the zip of
  completed build, the 'build.prop' file, the changelog, and the manifests.

  The changelog's "last build" timestamp files are stored at the base of the
  workspace. They will be updated only if '-u' is passed.

Examples:
  Build CyanogenMod 11.0 for the 'hammerhead' device if the source is in the
  current directory:
    $ ${0} -w /path/to/workspace -r cyanogenmod -b cm-11.0 -d hammerhead \\
        --sourcedir .

  Build CyanogenMod 11.0 nightlies for the 'jflte' device, keeping all
  source code in the workspace:
    $ ${0} -w /path/to/workspace -r cyanogenmod -b cm-11.0 -d jflte -s -u
EOF
}

args=$(getopt -o w:r:b:d:o:scu \
    -l workspace:rom:branch:device:romopts:sync,clean,updatecl,listroms,listromopts \
    -n build.sh -- "${@}")

if [ "${?}" -ne 0 ]; then
    echo "Failed to parse arguments!"
    show_usage
    exit 1
fi

eval set -- "${args}"

romopts=""
sync=false
clean=false
updatecl=false
listroms=false
listromopts=false
romdir=""

while true; do
    case "${1}" in
    -w|--workspace)
        shift
        workspace="${1}"
        shift
        ;;
    -r|--rom)
        shift
        rom="${1}"
        shift
        ;;
    -b|--branch)
        shift
        branch="${1}"
        shift
        ;;
    -d|--device)
        shift
        device="${1}"
        shift
        ;;
    -o|--romopts)
        shift
        romopts="${1}"
        shift
        ;;
    -s|--sync)
        sync=true
        shift
        ;;
    -c|--clean)
        clean=true
        shift
        ;;
    -u|--updatecl)
        updatecl=true
        shift
        ;;
    --listroms)
        listroms=true
        shift
        ;;
    --listromopts)
        listromopts=true
        shift
        ;;
    --sourcedir)
        shift
        romdir="${1}"
        shift
        ;;
    --)
        shift
        break
        ;;
    esac
done

topdir=$(cd "$(dirname "${0}")" && pwd)

if [[ "${listroms}" == "true" ]]; then
    basename -s .sh "${topdir}"/roms/*.sh
    exit
fi

argerror=false

if [[ -z "${workspace}" ]]; then
    echo "Workspace is not set. Be sure to pass the -w|--workspace parameter."
    argerror=true
fi

if [[ -z "${rom}" ]]; then
    echo "ROM is not set. Be sure to pass the -r|--rom parameter."
    argerror=true
fi

if [[ -z "${branch}" ]]; then
    echo "Branch is not set. Be sure to pass the -b|--branch parameter."
    argerror=true
fi

if [[ -z "${device}" ]]; then
    echo "Device is not set. Be sure to pass the -d|--device parameter."
    argerror=true
fi

if [[ "${argerror}" == "true" ]]; then
    exit 1
fi

source "${topdir}/builder/common.sh"
source "${topdir}/builder/distro.sh"
source "${topdir}/builder/rom.sh"

if ! detect_distro; then
    echo "Your Linux distribution is not supported!"
    exit 1
fi

callfunc ${distro}_checkdeps
callfunc ${distro}_envsetup

if ! load_rom; then
    echo "ROM ${rom} does not exist!"
    exit 1
fi

if [[ "${listromopts}" == "true" ]]; then
    listromopts
    exit
fi

###

cleanup() {
  #(repo forall -c "git reset --hard") >/dev/null || true
  rm -f "${romdir}"/.repo/local_manifests/dyn-*.xml
  rm -f "${romdir}".repo/local_manifests/roomservice.xml
  #callfunc "${rom}_cleanup"
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

exitiffail() {
    local run="${1}"
    shift
    "${run}" "${@}" || { echo "Failed." && exit 1; }
}

if [[ -z "${romdir}" ]]; then
    romdir="${workspace}/${rom}_${branch}"
fi
mkdir -p "${romdir}"
pushd "${romdir}"

exitiffail setdevice "${device}"
exitiffail setromopts "${romopts}"
exitiffail checkprereqs
exitiffail envsetup
exitiffail preinit
exitiffail repoinit
exitiffail presync

display_manifests

exitiffail syncrepos
exitiffail postsync
exitiffail prelunch
exitiffail prebuild
exitiffail build
exitiffail postbuild

popd

echo "Done."
