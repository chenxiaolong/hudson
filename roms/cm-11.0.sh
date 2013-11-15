reset_dirs_cm-11.0() {
  RESET_DIRS=('hardware/qcom/media-caf/'
              'hardware/qcom/audio-caf/'
              'hardware/qcom/display-caf/'
              'hardware/libhardware/'
              'frameworks/av/'
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
              'vendor/samsung/'
              'packages/apps/Dialer/'
              'packages/services/Telephony/'
              'external/clang/'
              'build/')

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=('hardware/libhardware_legacy/'
                  'device/samsung/msm8960-common/')

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

  pushd device/samsung/jf-common/
  apply_patch_file_git ${JF}/0001-Set-SELinux-to-permissive-mode.patch
  apply_patch_file_git ${JF}/0001-Don-t-build-SELinux-policy-for-now.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
  apply_patch_file_git ${JF}/0001-Add-Telephony-overlay-fixes-missing-LTE-toggle.patch
  apply_patch_file_git ${JF}/0001-Use-IRDA-service.patch
  apply_patch_file_git ${JF}/0001-Allow-external-SD-to-be-mounted.patch
  apply_patch_file_git ${JF}/0001-Enable-Host-Card-Emulation.patch
  # Revert "jf: Enable QC time services"
  git revert --no-edit 9223038d0886370c8957d279ba721d5c50aba74d
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

  pushd vendor/samsung/
  # Revert "jf: Update blobs"
  git revert --no-edit 25abb7ace77be2ad3c52df93dd7044d50b8fee1d
  popd

  pushd build/
  apply_patch_file_git ${PATCHES}/0001-Use-ccache-version-3.patch
  popd

  GERRIT_URL="http://review.cyanogenmod.org" \
  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# hardware/qcom/media-caf` \
    `# 'http://review.cyanogenmod.org/#/c/53030/'` `# Revert "mm-video: vidc: Add support for dynamic debug logging"`    \
    `# 'http://review.cyanogenmod.org/#/c/53034/'` `# mm-video: vdec: Support adaptive playback mode`                    \
    `# hardware/qcom/audio-caf` \
    `# 'http://review.cyanogenmod.org/#/c/52997/'` `# audio/msm7x30: Sync audio_policy with ALSA`                    \
    'http://review.cyanogenmod.org/#/c/53194/' `# alsa_sound: Initial changes for basic FM feature`                  \
    'http://review.cyanogenmod.org/#/c/53195/' `# alsa_sound: Add support for Voip`                                  \
    `# 'http://review.cyanogenmod.org/#/c/53023/'` `# msm8660: update audio policy`                                  \
    `# 'http://review.cyanogenmod.org/#/c/53166/'` `# msm8660: increase size of buffers to fit PROP_VALUE_MAX`       \
    'http://review.cyanogenmod.org/#/c/53196/' `# alsa_sound: Enable support for LPA/Tunnel audio playback`          \
    `# hardware/qcom/display-caf` \
    `# 'http://review.cyanogenmod.org/#/c/53339/'` `# gralloc: Add allocation support for sRGB formats`                  \
    `# 'http://review.cyanogenmod.org/#/c/53340/'` `# Replace sRGB_888 with sRGB_X_8888`                                 \
    `# 'http://review.cyanogenmod.org/#/c/53344/'` `# hwc: Add support to smooth streaming feature.`                     \
    `# 'http://review.cyanogenmod.org/#/c/53350/'` `# hwc: Fix rotator size allocation to max buffer size`               \
    `# device/samsung/jf-common` \
    `# 'http://review.cyanogenmod.org/#/c/53267/'` `# jf: selinux bringup`                                           \
    'http://review.cyanogenmod.org/#/c/53265/' `# jf: update wifi config`                                            \
    `# 'http://review.cyanogenmod.org/#/c/53266/'` `# jf: remove gsm/cdma overlay dirs`                              \
    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`                                                \
    `# frameworks/av` \
    'http://review.cyanogenmod.org/#/c/53324/' `# frameworks_av: Support pre-KitKat audio blobs`                     \
    `# 'http://review.cyanogenmod.org/#/c/53376/'` `# frameworks/av: Squashed commit of media features from CAF`         \
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
}
