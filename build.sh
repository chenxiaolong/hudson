#!/usr/bin/env bash

#set -ex
set -e

source common.sh

for i in distros/*.sh; do
  source ${i}
done

for i in roms/*.sh; do
  source ${i}
done

if [ -f /etc/arch-release ]; then
  DISTRO=arch
elif [ -f /etc/debian-release ]; then
  DISTRO=debian
elif [ -f /etc/fedora-release ]; then
  DISTRO=fedora
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

REPO=$(which repo)
if [ -z "$REPO" ]; then
  mkdir -p bin/
  curl https://dl-ssl.google.com/dl/googlesource/git-repo/repo > bin/repo
  chmod a+x bin/repo
fi

# Set up environment
if declare -f ${ROM}_envsetup >/dev/null; then
  ${ROM}_envsetup
else
  common_envsetup
fi

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
  ${ROM}_preinit
else
  common_preinit
fi

# Initialize repos
if declare -f ${ROM}_repoinit >/dev/null; then
  ${ROM}_repoinit
else
  common_repoinit
fi

if declare -f ${ROM}_presync >/dev/null; then
  ${ROM}_presync
else
  common_presync
fi

printline '='
echo "Core nanifest:"
printline '-'
cat .repo/manifest.xml
printline '='

for i in .repo/local_manifests/*.xml; do
  printline '='
  echo "${i}"
  printline '-'
  cat "${i}"
  printline '='
done

repo sync -d -c >/dev/null

if declare -f ${ROM}_postsync >/dev/null; then
  ${ROM}_postsync
else
  common_postsync
fi

if declare -f ${ROM}_translatedevice >/dev/null; then
  LUNCH=$(${ROM}_translatedevice ${LUNCH})
fi

if declare -f ${ROM}_prebuild >/dev/null; then
  ${ROM}_prebuild
else
  common_prebuild
fi

if declare -f ${ROM}_build >/dev/null; then
  ${ROM}_build
else
  common_build
fi

if declare -f ${ROM}_postbuild >/dev/null; then
  ${ROM}_postbuild
else
  common_postbuild
fi
