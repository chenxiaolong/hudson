aokp_translatedevice() {
  if ! grep -q "aokp_[a-zA-Z0-9]\+-userdebug" <<< ${1}; then
    echo "aokp_${1}-userdebug"
  fi
}

aokp_envsetup() {
  common_envsetup

  export BUILD_WITH_COLORS=0
}

aokp_presync() {
  common_presync

  ## TEMPORARY: Some kernels are building _into_ the source tree and messing
  ## up posterior syncs due to changes
  rm -rf kernel/*
}

aokp_repoinit() {
  repo init -u https://github.com/task650/platform_manifest.git -b ${REPO_BRANCH}
}

aokp_prebuild() {
  common_prebuild

  # Remove old zips
  rm -f "${OUT}"/aokp_*.zip*
}

aokp_postbuild() {
  common_postbuild

  for i in "${OUT}"/aokp_${LUNCH}_unofficial_*.zip*; do
    ln "${i}" "${WORKSPACE}/archive/"
  done

  unzip -p "${OUT}"/aokp_${LUNCH}_unofficial_*.zip system/build.prop > "${WORKSPACE}/archive/build.prop"
}
