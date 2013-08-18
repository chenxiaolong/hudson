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

  if grep -q jflte <<< ${LUNCH}; then
    pushd frameworks/base/
    #reset_git_state github/${REPO_BRANCH}

    # http://review.cyanogenmod.org/#/c/46770/
    apply_patch_file_git ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Add-Irda-System-Service.patch
    popd

    pushd hardware/libhardware/
    #reset_git_state github/${REPO_BRANCH}

    # http://review.cyanogenmod.org/#/c/46771/
    apply_patch_file_git ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Added-IrDA-HAL-Library.patch
    popd

    pushd device/samsung/jf-common/
    #reset_git_state github/${REPO_BRANCH}

    # http://review.cyanogenmod.org/#/c/46769/
    apply_patch_file_git ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Enable-Irda-service-via-overlay-and-HAL.patch

    # http://review.cyanogenmod.org/#/c/47908/
    apply_patch_file_git ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Expose-Irda-feature.patch
    popd
  fi

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
