#!/usr/bin/env bash

#set -ex
set -e

source common.sh

for i in distros/*.sh; do
  source ${i}
done

for i in roms/rom_*.sh; do
  source ${i}
done

if [ -f /etc/arch-release ]; then
  DISTRO=arch
elif [ -f /etc/debian-release ]; then
  DISTRO=debian
elif [ -f /etc/fedora-release ]; then
  DISTRO=fedora
elif [ -f /etc/os-release ]; then
  if grep -q Ubuntu /etc/os-release; then
    DISTRO=ubuntu
  fi
fi

if [ -z "${DISTRO}" ]; then
  echo "Your Linux distribution is not supported!"
  exit 1
fi

if declare -f ${DISTRO}_checkdeps >/dev/null; then
  ${DISTRO}_checkdeps
fi

if declare -f ${DISTRO}_envsetup >/dev/null; then
  ${DISTRO}_envsetup
fi

if [ -z "${HOME}" ]; then
  echo HOME not in environment, guessing...
  export HOME=$(awk -F: -v v="${USER}" '{if ($1==v) print $6}' /etc/passwd)
fi

if [ -z "${WORKSPACE}" ]; then
  echo WORKSPACE not specified
  exit 1
fi

if [ -z "${CLEAN}" ]; then
  echo CLEAN not specified
  exit 1
fi

if [ -z "${ROM}" ]; then
  echo ROM not specified
  exit 1
fi

if [ -z "${REPO_BRANCH}" ]; then
  echo REPO_BRANCH not specified
  exit 1
fi

if [ -z "${LUNCH}" ]; then
  echo LUNCH not specified
  exit 1
fi

if [ -z "${RELEASE_TYPE}" ]; then
  echo RELEASE_TYPE not specified
  exit 1
fi

if [ -z "${SYNC}" ]; then
  SYNC=true
fi

# colorization fix in Jenkins
export CL_RED="\"\033[31m\""
export CL_GRN="\"\033[32m\""
export CL_YLW="\"\033[33m\""
export CL_BLU="\"\033[34m\""
export CL_MAG="\"\033[35m\""
export CL_CYN="\"\033[36m\""
export CL_RST="\"\033[0m\""

cd $WORKSPACE
rm -rf archive
mkdir -p archive

export PATH="$(pwd)/bin:${PATH}"

if ! which repo &>/dev/null; then
  mkdir -p bin/
  curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > bin/repo
  chmod a+x bin/repo
  REPO="$(pwd)/bin/repo"
else
  REPO="$(which repo)"
fi

# Set up environment
if declare -f ${ROM}_envsetup >/dev/null; then
  time ${ROM}_envsetup
else
  time common_envsetup
fi
echo "^^^ TIME SPENT IN envsetup ^^^"

# Create build directory
BUILD_DIR=${ROM}_${REPO_BRANCH}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cleanup() {
  #(repo forall -c "git reset --hard") >/dev/null || true
  rm -f .repo/local_manifests/dyn-*.xml
  rm -f .repo/local_manifests/roomservice.xml
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

# Stuff to do before initializing repos
if declare -f ${ROM}_preinit >/dev/null; then
  time ${ROM}_preinit
else
  time common_preinit
fi
echo "^^^ TIME SPENT IN preinit ^^^"

# Initialize repos
if declare -f ${ROM}_repoinit >/dev/null; then
  time ${ROM}_repoinit
else
  time common_repoinit
fi
echo "^^^ TIME SPENT IN repoinit ^^^"

if declare -f ${ROM}_presync >/dev/null; then
  time ${ROM}_presync
else
  time common_presync
fi
echo "^^^ TIME SPENT IN presync ^^^"

printline '='
echo "Core nanifest:"
printline '-'
cat .repo/manifest.xml
printline '='

LOCAL_MANIFESTS="$(find .repo/local_manifests -name '*.xml' || true)"
if [[ ! -z "${LOCAL_MANIFESTS}" ]]; then
  for i in ${LOCAL_MANIFESTS}; do
    printline '='
    echo "${i}"
    printline '-'
    cat "${i}"
    printline '='
  done
fi

if [ "x${SYNC}" = "xtrue" ]; then
  time repo sync -d -c >/dev/null
  echo "^^^ TIME SPENT ON repo sync ^^^"
else
  echo '### repo sync disabled for this build! ###'
fi

if declare -f ${ROM}_postsync >/dev/null; then
  time ${ROM}_postsync
else
  time common_postsync
fi
echo "^^^ TIME SPENT IN postsync ^^^"

if declare -f ${ROM}_translatedevice >/dev/null; then
  export LUNCH_OLD=${LUNCH}
  LUNCH=$(${ROM}_translatedevice ${LUNCH})
fi

if declare -f ${ROM}_prelunch >/dev/null; then
  time ${ROM}_prelunch
else
  time common_prelunch
fi
echo "^^^ TIME SPENT IN prelunch ^^^"

# Hackish, but necessary because lunch is appending things to the beginning of
# $PATH. envsetup should be idempotent anyway.
if declare -f ${DISTRO}_envsetup >/dev/null; then
  ${DISTRO}_envsetup
fi

if declare -f ${ROM}_prebuild >/dev/null; then
  time ${ROM}_prebuild
else
  time common_prebuild
fi
echo "^^^ TIME SPENT IN prebuild ^^^"

if declare -f ${ROM}_build >/dev/null; then
  time ${ROM}_build
else
  time common_build
fi
echo "^^^ TIME SPENT IN build ^^^"

if declare -f ${ROM}_postbuild >/dev/null; then
  time ${ROM}_postbuild
else
  time common_postbuild
fi
echo "^^^ TIME SPENT IN postbuild ^^^"
