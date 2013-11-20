reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'hardware/qcom/audio-caf/'
    'device/samsung/jf-common/'
    'art/'
    'device/samsung/qcom-common/'
    'packages/providers/ContactsProvider/'
    'packages/apps/Dialer/'
    'packages/services/Telephony/'
    'external/clang/'
    'system/core/'
    'kernel/samsung/jf/'
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

  GERRIT_URL="http://review.cyanogenmod.org" \
  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# hardware/qcom/audio-caf` \
    'http://review.cyanogenmod.org/#/c/53194/' `# alsa_sound: Initial changes for basic FM feature`                  \
    'http://review.cyanogenmod.org/#/c/53195/' `# alsa_sound: Add support for Voip`                                  \
    'http://review.cyanogenmod.org/#/c/53196/' `# alsa_sound: Enable support for LPA/Tunnel audio playback`          \
    `# device/samsung/jf-common` \
    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`                                                \
    'http://review.cyanogenmod.org/#/c/53622/' `# Fix sdcard in 4.4 for app r/w access`                              \
    'http://review.cyanogenmod.org/#/c/53969/' `# jf: fix fstab`                                                     \
    `# system/core` \
    'http://review.cyanogenmod.org/#/c/53102/' `# healthd: allow devices to provide their own libhealthd`            \
    'http://review.cyanogenmod.org/#/c/53075/' `# Add back DurationTimer to fix camera.msm8960 load`                 \
    'http://review.cyanogenmod.org/#/c/53310/' `# Add support for QCs time_daemon`                                   \
    `# device/samsung/qcom-common` \
    'http://review.cyanogenmod.org/#/c/53115/' `# qcom: allow properly querying of battery capacity`                 \
    `# packages/apps/Dialer` \
    'http://review.cyanogenmod.org/#/c/53302/' `# Dialer: Update Icons to KitKat`                                    \
    `# packages/services/Telephony` \
    'http://review.cyanogenmod.org/#/c/53356/' `# Telephony: Update Icons to Kitkat`                                 \
    `# external/clang` \
    'http://review.cyanogenmod.org/#/c/53126/' `# clang: add support for neon-vfp instructions`

  pushd device/samsung/jf-common/
  apply_patch_file_git ${DUALBOOT}/0001-jf-Add-dual-booting-support.patch
  popd
}
