#!/bin/bash

curdir=$(cd $(dirname ${0}) && pwd)

basedir=${curdir}/pacman_cm-10.2

reset=true
if [ ! -z "${1}" -a "${1}" == "--noreset" ]; then
  reset=false
fi

apply_patch_in() {
  pushd ${1} >/dev/null
  shift
  for i in ${*}; do
    git am ${basedir}/${i}
  done
  popd >/dev/null
}

reset_to_branch() {
  pushd ${1} >/dev/null
  if [ "${reset}" = "true" ]; then
    git am --abort &>/dev/null || true
    git reset --hard ${2} >/dev/null
    git clean -fdx >/dev/null
  fi
  popd >/dev/null
}

# system/vold/
reset_to_branch system/vold/ cm/cm-10.2
apply_patch_in system/vold/ \
  move-app-to-sd/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch

# device/samsung/jf-common/
reset_to_branch device/samsung/jf-common/ github/cm-10.2
apply_patch_in device/samsung/jf-common/ \
  move-app-to-sd/0001-Set-externalSd-attribute-for-the-external-SD-card.patch

# packages/apps/Settings/
reset_to_branch packages/apps/Settings/ pac/cm-10.2
apply_patch_in packages/apps/Settings/ \
  move-app-to-sd/0001-Enable-moving-applications-to-the-external-SD-card.patch \
  high-touch-sensitivity/0001-Add-preferences-for-high-touch-sensitivity.patch \
  high-touch-sensitivity/0001-Auto-copied-translations-for-high-touch-sensitivity.patch

# frameworks/base/
reset_to_branch frameworks/base/ pac/cm-10.2
apply_patch_in frameworks/base/ \
  move-app-to-sd/0001-Framework-changes-for-moving-applications-to-externa.patch

# frameworks/opt/hardware/
reset_to_branch frameworks/opt/hardware/ cm/cm-10.2
apply_patch_in frameworks/opt/hardware/ \
  high-touch-sensitivity/0001-Hardware-Add-high-touch-sensitivity-support.patch

# hardware/samsung/
reset_to_branch hardware/samsung/ github/cm-10.2
apply_patch_in hardware/samsung/ \
  high-touch-sensitivity/0001-Samsung-add-support-for-high-touch-sensitivity.patch
