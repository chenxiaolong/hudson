reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'hardware/qcom/audio-caf/'
    'hardware/libhardware/'
    'frameworks/base/'
    'system/core/'
    'device/samsung/jf-common/'
    'art/'
    'device/samsung/qcom-common/'
    'packages/apps/Settings/'
    'frameworks/opt/hardware/'
    'hardware/samsung/'
    'packages/providers/ContactsProvider/'
    'system/vold/'
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
  )

  for i in ${RESET_DIRS[@]} ${RESET_DIRS_OLD[@]}; do
    if [ -d "${i}" ]; then
      reset_git_state ${i} github/${REPO_BRANCH}
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  JF=${PATCHES}/jf
  HIGHTOUCHSENSITIVITY=${PATCHES}/high-touch-sensitivity
  FACEBOOKSYNC=${PATCHES}/facebook-sync
  MOVEAPPTOSD=${PATCHES}/move-app-to-sd
  SENSORS=${PATCHES}/sensors
  DUALBOOT=${PATCHES}/dual-boot
  BCMDHD=${PATCHES}/bcmdhd

  pushd device/samsung/jf-common/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
  apply_patch_file_git ${JF}/0001-Add-Telephony-overlay-fixes-missing-LTE-toggle.patch
  apply_patch_file_git ${JF}/0001-Use-IRDA-service.patch
  apply_patch_file_git ${JF}/0001-Enable-Host-Card-Emulation.patch
  # Revert "jf: remove irda stuff"
  git revert --no-edit 052665362ab0ee6763a541e124baf4166e9fed3f
  popd

  pushd art/
  apply_patch_file_git ${PATCHES}/0001-Run-generate-operator-out.py-with-Python-2.patch
  popd

  pushd frameworks/base/
  apply_patch_file_git ${JF}/0001-Irda-Add-Irda-System-Service.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
  # Thanks to Team Guppy for finding the commits to revert!
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/eeeca93aa110bc2b59290b5e048c15162bfb1780
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/9dbf6faeb2ddd6fd031f51e788dc437e496cc1ce
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/f64cbd2b4512ad1b2c6cbaabe08a22a097a26b6a
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/eef1ffd30fb050af3a9b51af4ff62ff7323fb593
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/a33672672c380b95843226c48858224e2d299057
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/f95516fd54f1ed5359e4b79d748172a5e1a80c19
  # https://github.com/TEAM-Gummy/android_frameworks_base/commit/6dd50a6edb7916256ef83fd7e938e001aad6b465
  apply_patch_file_git ${SENSORS}/0001-Revert-Fix-registerListener-and-flush-bugs.patch
  apply_patch_file_git ${SENSORS}/0002-Revert-Sensor-batching-APIs-for-review.patch
  apply_patch_file_git ${SENSORS}/0003-Revert-Fix-for-build-breakage.-Remove-documentation-.patch
  apply_patch_file_git ${SENSORS}/0004-Revert-Sensor-batching.-Implementation-for-registerL.patch
  apply_patch_file_git ${SENSORS}/0005-Revert-Fix-for-build-breakage.-Correcting-the-docume.patch
  apply_patch_file_git ${SENSORS}/0006-Revert-Adding-new-constants-for-STEP_DETECTOR-STEP_C.patch
  apply_patch_file_git ${SENSORS}/0007-Revert-Revert-Revert-be-more-robust-with-handling-un.patch
  popd

  pushd hardware/libhardware/
  apply_patch_file_git ${JF}/0001-Irda-Added-IrDA-HAL-Library.patch
  popd

  pushd packages/apps/Settings/
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Enable-moving-applications-to-the-external-SD-card.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-app-moving-setting-to-development-options.patch
  popd

  pushd frameworks/opt/hardware/
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-class-for-enabling-and-disabling-moving-apps-to-.patch
  popd

  pushd hardware/samsung/
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
  popd

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  pushd system/vold/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch
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

  pushd system/core/
  apply_patch_file_git ${DUALBOOT}/0001-init.rc-Dual-boot-preparation.patch
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
