reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'hardware/qcom/audio-caf/'
    'device/samsung/jf-common/'
    'art/'
    'device/samsung/qcom-common/'
    'packages/providers/ContactsProvider/'
    'frameworks/native/'
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
  )

  for i in ${RESET_DIRS[@]} ${RESET_DIRS_OLD[@]}; do
    if [ -d "${i}" ]; then
      reset_git_state ${i} github/${REPO_BRANCH}
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  HIGHTOUCHSENSITIVITY=${PATCHES}/high-touch-sensitivity
  FACEBOOKSYNC=${PATCHES}/facebook-sync
  MOVEAPPTOSD=${PATCHES}/move-app-to-sd
  SENSORS=${PATCHES}/sensors
  DUALBOOT=${PATCHES}/dual-boot
  BCMDHD=${PATCHES}/bcmdhd

  pushd art/
  apply_patch_file_git ${PATCHES}/0001-Run-generate-operator-out.py-with-Python-2.patch
  popd

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  pushd frameworks/native/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Calculate-application-sizes-correctly.patch
  # Thanks to Team Guppy for finding the commits to revert!
  # https://github.com/TEAM-Gummy/platform_frameworks_native/commit/4980b82179fb742a830e3fc68781e35bb4a3ee81
  # https://github.com/TEAM-Gummy/platform_frameworks_native/commit/9f73d1e2e1ca4f59abe5a5ef2b607b8996f67bd2
  # https://github.com/TEAM-Gummy/platform_frameworks_native/commit/59fcdbef1e75bef84d22f8353544973807bb785a
  apply_patch_file_git ${SENSORS}/0001-revert-to-4.3-sensors-for-testing.patch
  apply_patch_file_git ${SENSORS}/0002-complete-the-sensor-swapout.patch
  apply_patch_file_git ${SENSORS}/0003-Make-Flattenable-not-virtual.patch
  popd

  pushd kernel/samsung/jf/
  # Patches from https://github.com/franciscofranco/hammerhead.git
  # Thanks to Entropy512/Andrew Dodd and Francisco Franco for finding them!
  # https://plus.google.com/109625418534467664286/posts/7X4sUWPKeGX

  # 837961187ec3ecf82a11b89d7cf8fb267d3ed9ce
  #apply_patch_file_git ${BCMDHD}/0001-net-wireless-bcmdhd-fixed-power-consumption-issue-of.patch
  # 24bf61016206ba6fb0edb2b4593f8197fd89137e
  #apply_patch_file_git ${BCMDHD}/0001-net-wireless-bcmdhd-Fixed-a-problem-of-buganizer-iss.patch
  # 5dd724eb19f768e641041a0b897c5e8464077949
  #apply_patch_file_git ${BCMDHD}/0001-net-wireless-bcmdhd-reduced-the-wakelock-time-of-RX-.patch
  # c8092f60419fcec95cc5c4b458de9d6be2fc60fc
  #apply_patch_file_git ${BCMDHD}/0001-net-wireless-bcmdhd-Change-DTIM-skip-policy-in-suspe.patch
  # 6076d5a4d5724b6f941a0ca86d62708786cdab84
  #apply_patch_file_git ${BCMDHD}/0001-drivers-bcmdhd-filter-only-unicast-packets-during-su.patch
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
