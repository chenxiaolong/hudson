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
              'frameworks/base/')

  for i in ${RESET_DIRS[@]}; do
    pushd ${i} && reset_git_state github/${REPO_BRANCH} && popd
  done

  #if grep -q jflte <<< ${LUNCH}; then
    MOVEAPPTOSD=${WORKSPACE}/hudsom/roms/${REPO_BRANCH}/move-app-to-sd

    pushd system/vold/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch
    popd

    pushd device/samsung/jf-common/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
    popd

    pushd packages/apps/Settings/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Enable-moving-applications-to-the-external-SD-card.patch
    popd

    pushd frameworks/base/
    apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
    popd
  #fi

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    'http://review.cyanogenmod.org/#/c/48359/' \
    'http://review.cyanogenmod.org/#/c/48352/'

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
