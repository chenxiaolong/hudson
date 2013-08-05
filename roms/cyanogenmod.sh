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
  common_prebuild

  # Remove old zips
  rm -f "${OUT}"/cm-*.zip*

  if grep -q jflte <<< ${LUNCH}; then
    pushd frameworks/base/
    git checkout github/${REPO_BRANCH}
    git clean -fdx
    git diff | patch -p1 -R
    #git fetch http://review.cyanogenmod.org/CyanogenMod/android_frameworks_base refs/changes/80/44580/9 && git cherry-pick FETCH_HEAD
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Add-Irda-System-Service-for-Samsung-devices.patch
    popd

    pushd hardware/libhardware/
    git checkout github/${REPO_BRANCH}
    git clean -fdx
    git diff | patch -p1 -R
    #git fetch http://review.cyanogenmod.org/CyanogenMod/android_hardware_libhardware refs/changes/83/44783/4 && git checkout FETCH_HEAD
    rm -f include/hardware/irda.h
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Added-IrDA-HAL-Library.patch
    popd

    pushd device/samsung/jf-common/
    git checkout github/${REPO_BRANCH}
    git clean -fdx
    git diff | patch -p1 -R
    #git fetch http://review.cyanogenmod.org/CyanogenMod/android_device_samsung_jf-common refs/changes/91/44691/5 && git checkout FETCH_HEAD
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Irda-Enable-Irda-service-via-overlay-and-HAL.patch

    # git fetch http://review.cyanogenmod.org/CyanogenMod/android_device_samsung_jf-common refs/changes/86/46286/1 && git format-patch -1 FETCH_HEAD
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-jf-move-camera-option-to-gallery2.patch
    popd

    pushd packages/apps/Gallery2/
    git checkout github/${REPO_BRANCH}
    git clean -fdx
    git diff | patch -p1 -R
    # git fetch http://review.cyanogenmod.org/CyanogenMod/android_packages_apps_Gallery2 refs/changes/87/46287/9 && git format-patch -1 FETCH_HEAD
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Camera-Bring-Samsung-camera-fixes-and-features-to-4..patch
    popd

    pushd packages/apps/Focal/
    git checkout github/${REPO_BRANCH}
    git clean -fdx
    git diff | patch -p1 -R
    # git fetch http://review.cyanogenmod.org/CyanogenMod/android_packages_apps_Focal refs/changes/86/46986/2 && git format-patch -1 FETCH_HEAD
    git am ${WORKSPACE}/hudson/roms/${REPO_BRANCH}/0001-Focal-add-new-api-for-detecting-the-widget-we-are-in.patch
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
