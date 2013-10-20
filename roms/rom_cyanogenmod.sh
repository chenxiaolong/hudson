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
              'hardware/samsung/'
              'external/busybox/'
              'vendor/cm/'
              'system/core/'
              'build/'
              'frameworks/native/'
              'packages/providers/ContactsProvider/')

  for i in ${RESET_DIRS[@]}; do
    pushd ${i} && reset_git_state github/${REPO_BRANCH} && popd
  done

  #if grep -q jflte <<< ${LUNCH}; then
    MOVEAPPTOSD=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/move-app-to-sd
    HIGHTOUCHSENSITIVITY=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/high-touch-sensitivity
    DUALBOOT=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/dual-boot
    FACEBOOKSYNC=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/facebook-sync
    GERRIT=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/gerrit
    OMNI=${WORKSPACE}/hudson/roms/${REPO_BRANCH}/omni

    pushd system/vold/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Vold-Do-not-mount-ASEC-containers-if-moving-apps-to-.patch
    popd

    pushd device/samsung/jf-common/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
    apply_patch_file_git ${DUALBOOT}/0001-jf-Add-dual-booting-support.patch
    popd

    pushd packages/apps/Settings/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Enable-moving-applications-to-the-external-SD-card.patch
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-app-moving-setting-to-development-options.patch
    apply_patch_file_git ${GERRIT}/48359/0001-Add-configuraion-for-showing-statusbar-on-top-of-ful.patch
    apply_patch_file_git ${GERRIT}/51228/0001-Add-configuration-for-autounhiding-statusbar-on-new-.patch
    popd

    pushd frameworks/base/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-Check-of-moving-apps-to-SD-is-disabled.patch
    apply_patch_file_git ${OMNI}/53/PS19_0001-WIP-Multi-window.patch
    popd

    pushd frameworks/opt/hardware/
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-class-for-enabling-and-disabling-moving-apps-to-.patch
    popd

    pushd hardware/samsung/
    apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
    popd

    pushd external/busybox/
    apply_patch_file_git ${DUALBOOT}/0001-Busybox-Include-in-boot-image.patch
    popd

    pushd vendor/cm/
    apply_patch_file_git ${DUALBOOT}/0001-Add-helper-script-for-dual-boot-detection-in-updater.patch
    popd

    pushd system/core/
    apply_patch_file_git ${DUALBOOT}/0001-init.rc-Dual-boot-preparation.patch
    popd

    pushd build/
    apply_patch_file_git ${DUALBOOT}/0001-Allow-dual-boot-installation-in-updater-script.patch
    popd

    pushd frameworks/native/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Calculate-application-sizes-correctly.patch
    popd

    pushd packages/providers/ContactsProvider/
    apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
    popd
  #fi

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# http://forum.xda-developers.com/showpost.php?p=46631818&postcount=2186` \
    'http://review.cyanogenmod.org/#/c/52009/' \
    'http://review.cyanogenmod.org/#/c/52006/' \
    'http://review.cyanogenmod.org/#/c/52005/' \
    'http://review.cyanogenmod.org/#/c/52004/' \
    'http://review.cyanogenmod.org/#/c/52003/' \
    'http://review.cyanogenmod.org/#/c/52002/' \
    'http://review.cyanogenmod.org/#/c/52001/' \
    `# Native screen sharing API` \
    'http://review.cyanogenmod.org/#/c/50449/' \
    `# Swipe to show statusbar` \
    'http://review.cyanogenmod.org/#/c/51229/' \
    `# 'http://review.cyanogenmod.org/#/c/51228/' # Patch fixed manually` \
    `# 'http://review.cyanogenmod.org/#/c/48359/' # Patch fixed manually` \
    'http://review.cyanogenmod.org/#/c/48352/' || \
    echo '*** FAILED TO APPLY PATCHES: CYANOGENMOD GERRIT SERVER IS PROBABLY DOWN ***'

  if [ ! -z "${CM_NIGHTLY}" ]; then
    make update-api
  fi

  vendor/cm/get-prebuilts
}

cyanogenmod_postbuild() {
  common_postbuild

  for i in "${OUT}"/cm-*.zip*; do
    ln "${i}" "${WORKSPACE}/archive/"
  done

  unzip -p "${OUT}"/cm-*.zip system/build.prop > "${WORKSPACE}/archive/build.prop"
}
