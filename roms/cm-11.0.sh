reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'device/samsung/jf-common/'
    'art/'
    'packages/providers/ContactsProvider/'
    'packages/apps/Dialer/'
    'packages/services/Telephony/'
    'system/core/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'hardware/libhardware_legacy/'
    'device/samsung/msm8960-common/'
    'hardware/qcom/media-caf/'
    'hardware/qcom/display-caf/'
    'frameworks/av/'
    'vendor/samsung/'
    'external/busybox/'
    'vendor/cm/'
    'build/'
    'hardware/libhardware/'
    'frameworks/opt/hardware/'
    'hardware/samsung/'
    'system/vold/'
    'packages/apps/Settings/'
    'frameworks/base/'
    'frameworks/native/'
    'device/samsung/qcom-common/'
    'external/clang/'
    'kernel/samsung/jf/'
    'hardware/qcom/audio-caf/'
  )

  for i in ${RESET_DIRS[@]} ${RESET_DIRS_OLD[@]}; do
    if [ -d "${i}" ]; then
      reset_git_state ${i} github/${REPO_BRANCH}
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  FACEBOOKSYNC=${PATCHES}/facebook-sync
  DUALBOOT=${PATCHES}/dual-boot

  pushd art/
  apply_patch_file_git ${PATCHES}/0001-Run-generate-operator-out.py-with-Python-2.patch
  popd

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# device/samsung/jf-common` \
    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`                                                \
    'http://review.cyanogenmod.org/#/c/53969/' `# jf: fix fstab`                                                     \
    `# system/core` \
    'http://review.cyanogenmod.org/#/c/53075/' `# Add back DurationTimer to fix camera.msm8960 load`                 \
    'http://review.cyanogenmod.org/#/c/53310/' `# Add support for QCs time_daemon`                                   \
    `# packages/apps/Dialer` \
    'http://review.cyanogenmod.org/#/c/53302/' `# Dialer: Update Icons to KitKat`                                    \
    `# packages/services/Telephony` \
    'http://review.cyanogenmod.org/#/c/53356/' `# Telephony: Update Icons to Kitkat`                                 \
    `# Camera stuff` \
    Iff859f68f7097a36262bd24c0face0edf63f4a4c \
    I26898b82f6c9ab81e6f1681805de229e4ac2f308 \
    I56739157380f596c9f3bbbe7aecd8f532d619c72 \
    Ia0f5716d5e6815d249040b08313482a103a36863 \
    I216502fe032a89f69e1aea11bc50c51634d40991 \
    Ib36bd21c9a76b45bced3eee2f25acc35b5d82b30

  pushd device/samsung/jf-common/
  apply_patch_file_git ${DUALBOOT}/0001-jf-Add-dual-booting-support.patch
  popd
}
