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

  export GERRIT_URL="http://review.cyanogenmod.org"

  source ${WORKSPACE}/hudson/roms/${REPO_BRANCH}.sh
}

cyanogenmod_presync() {
  common_presync

  ## TEMPORARY: Some kernels are building _into_ the source tree and messing
  ## up posterior syncs due to changes
  rm -rf kernel/*

  reset_dirs_${REPO_BRANCH}
}

cyanogenmod_repoinit() {
  #repo init -u https://github.com/CyanogenMod/android.git -b ${REPO_BRANCH}
  repo init -u https://github.com/chenxiaolong/CM_android.git -b ${REPO_BRANCH}
}

cyanogenmod_postsync() {
  common_postsync
}

cyanogenmod_prebuild() {
  common_prebuild

  # Remove old zips
  rm -f "${OUT}"/cm-*.zip*

  apply_patches_${REPO_BRANCH}

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
