cyanogenmod_translatedevice() {
  if ! grep -q "cm_[a-zA-Z0-9]\+-userdebug" <<< ${1}; then
    echo "cm_${1}-userdebug"
  fi
}

cyanogenmod_envsetup() {
  common_envsetup

  export BUILD_WITH_COLORS=0

  if [ ! -z "${BUILD_USER_ID}" ]; then
    export RELEASE_TYPE=CM_EXPERIMENTAL
  fi

  case "${RELEASE_TYPE}" in
  CM_NIGHTLY)
    export CM_NIGHTLY=true;;
  CM_EXPERIMENTAL)
    export CM_EXPERIMENTAL=true;;
  CM_RELEASE)
    export CM_RELEASE=true;;
  esac

#  if [ ! -z "${CM_EXTRAVERSION}" ]; then
#    export CM_EXPERIMENTAL=true
#    unset CM_NIGHTLY CM_RELEASE
#  fi
}

cyanogenmod_presync() {
  common_presync

  ## TEMPORARY: Some kernels are building _into_ the source tree and messing
  ## up posterior syncs due to changes
  rm -rf kernel/*
}

cyanogenmod_repoinit() {
  repo init -u https://github.com/CyanogenMod/android.git -b ${REPO_BRANCH}
}

cyanogenmod_postsync() {
  common_postsync

  vendor/cm/get-prebuilts
}

cyanogenmod_prebuild() {
  export GERRIT_URL="http://review.cyanogenmod.org"

  common_prebuild

  # Remove old zips
  rm -f "${OUT}"/cm-*.zip*

  RESET_DIRS=('system/vold/'
              'device/samsung/jf-common/'
              'packages/apps/Settings/'
              'frameworks/base/'
              'frameworks/opt/hardware/'
              'hardware/samsung/')

  for i in ${RESET_DIRS[@]}; do
    pushd ${i} && reset_git_state github/${REPO_BRANCH} && popd
  done

  #if grep -q jflte <<< ${LUNCH}; then
    MOVEAPPTOSD=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/move-app-to-sd
    HIGHTOUCHSENSITIVITY=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/high-touch-sensitivity
    DUALBOOT=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/dual-boot

    pushd system/vold/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch
    popd

    pushd device/samsung/jf-common/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
    popd

    pushd packages/apps/Settings/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Enable-moving-applications-to-the-external-SD-card.patch
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
    popd

    pushd frameworks/base/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
    popd

    pushd frameworks/opt/hardware/
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
    popd

    pushd hardware/samsung/
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
    popd

    pushd external/busybox/
    apply_patch_file_git ${DUALBOOT}/0001-Busybox-Include-in-boot-image.patch
    popd
  #fi

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    'http://review.cyanogenmod.org/#/c/48359/' \
    'http://review.cyanogenmod.org/#/c/48352/' || \
    echo '*** FAILED TO APPLY PATCHES: CYANOGENMOD GERRIT SERVER IS PROBABLY DOWN ***'

  if [ ! -z "${CM_NIGHTLY}" ]; then
    make update-api
  fi
}

cyanogenmod_postbuild() {
  common_postbuild

  for i in "${OUT}"/cm-*.zip*; do
    ln "${i}" "${WORKSPACE}/archive/"
  done

  unzip -p "${OUT}"/cm-*.zip system/build.prop > "${WORKSPACE}/archive/build.prop"
}
