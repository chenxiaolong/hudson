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

  if [ ! -z "${CM_EXTRAVERSION}" ]; then
    export CM_EXPERIMENTAL=true
    unset CM_NIGHTLY CM_RELEASE
  fi
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
  common_prebuild

  # Remove old zips
  rm -f "${OUT}"/cm-*.zip*

  pushd frameworks/base/
  git fetch http://review.cyanogenmod.org/CyanogenMod/android_frameworks_base refs/changes/80/44580/9 && git cherry-pick FETCH_HEAD
  popd

  pushd hardware/libhardware/
  git fetch http://review.cyanogenmod.org/CyanogenMod/android_hardware_libhardware refs/changes/83/44783/4 && git checkout FETCH_HEAD
  popd

  pushd device/samsung/jf-common/
  git fetch http://review.cyanogenmod.org/CyanogenMod/android_device_samsung_jf-common refs/changes/91/44691/5 && git checkout FETCH_HEAD
  popd
}

cyanogenmod_postbuild() {
  common_postbuild

  for i in "${OUT}"/cm-*.zip*; do
    ln "${i}" "${WORKSPACE}/archive/"
  done

  unzip -p "${OUT}"/cm-*.zip system/build.prop > "${WORKSPACE}/archive/build.prop"
}
