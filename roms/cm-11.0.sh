reset_dirs_cm-11.0() {
  RESET_DIRS=('hardware/qcom/media-caf/'
              'hardware/qcom/audio-caf/'
              'hardware/qcom/display-caf/'
              'hardware/libhardware/'
              'hardware/libhardware_legacy/'
              'frameworks/av/'
              'frameworks/base/'
              'system/core/'
              'device/samsung/jf-common/'
              'device/samsung/msm8960-common/'
              'art/'
              'device/samsung/qcom-common/'
              'packages/apps/Settings/'
              'frameworks/opt/hardware/'
              'hardware/samsung/'
              'packages/providers/ContactsProvider/'
              'system/vold/'
              'frameworks/native/')

  for i in ${RESET_DIRS[@]}; do
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

  pushd device/samsung/jf-common/
  apply_patch_file_git ${JF}/0001-Set-SELinux-to-permissive-mode.patch
  apply_patch_file_git ${JF}/0001-Do-not-mount-apnhlos-or-mdm-under-a-SELinux-context.patch
  apply_patch_file_git ${JF}/0001-Don-t-build-SELinux-policy-for-now.patch
  apply_patch_file_git ${JF}/0001-Disable-some-overlays-for-now.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
  popd

  pushd device/samsung/msm8960-common/
  apply_patch_file_git ${JF}/0001-neon-vfpv4-neon.patch
  popd

  pushd art/
  apply_patch_file_git ${PATCHES}/0001-Run-generate-operator-out.py-with-Python-2.patch
  popd

  pushd frameworks/base/
  apply_patch_file_git ${JF}/0001-Irda-Add-Irda-System-Service.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
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
  popd

  GERRIT_URL="http://review.cyanogenmod.org" \
  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# hardware/qcom/media-caf` \
    'http://review.cyanogenmod.org/#/c/53030/' `# Revert "mm-video: vidc: Add support for dynamic debug logging"`    \
    'http://review.cyanogenmod.org/#/c/53031/' `# camera bringup changes hardware-qcom-media`                        \
    'http://review.cyanogenmod.org/#/c/53032/' `# media: compilation fix for updated sdk version`                    \
    'http://review.cyanogenmod.org/#/c/53033/' `# Dashplayer: enable adaptive playback based on codec format key`    \
    'http://review.cyanogenmod.org/#/c/53034/' `# mm-video: vdec: Support adaptive playback mode`                    \
    'http://review.cyanogenmod.org/#/c/53035/' `# mm-video: vidc: set stride in gralloc-metadata for adaptive-playback` \
    `# hardware/qcom/audio-caf` \
    `# 'http://review.cyanogenmod.org/#/c/52997/'` `# audio/msm7x30: Sync audio_policy with ALSA`                    \
    'http://review.cyanogenmod.org/#/c/53194/' `# alsa_sound: Initial changes for basic FM feature`                  \
    'http://review.cyanogenmod.org/#/c/53195/' `# alsa_sound: Add support for Voip`                                  \
    `# 'http://review.cyanogenmod.org/#/c/53023/'` `# msm8660: update audio policy`                                  \
    `# 'http://review.cyanogenmod.org/#/c/53166/'` `# msm8660: increase size of buffers to fit PROP_VALUE_MAX`       \
    'http://review.cyanogenmod.org/#/c/53196/' `# alsa_sound: Enable support for LPA/Tunnel audio playback`          \
    `# hardware/qcom/display-caf` \
    'http://review.cyanogenmod.org/#/c/53337/' `# hwc: Bump up version to 1.3`                                       \
    'http://review.cyanogenmod.org/#/c/53338/' `# hwc: Punt layers with non integral source crop`                    \
    'http://review.cyanogenmod.org/#/c/53339/' `# gralloc: Add allocation support for sRGB formats`                  \
    'http://review.cyanogenmod.org/#/c/53340/' `# Replace sRGB_888 with sRGB_X_8888`                                 \
    'http://review.cyanogenmod.org/#/c/53341/' `# get rid of HAL pixelformats 5551 and 4444`                         \
    'http://review.cyanogenmod.org/#/c/53342/' `# gralloc: Add padding byte for YUV 420`                             \
    'http://review.cyanogenmod.org/#/c/53343/' `# display: Add support to HAL_PIXEL_FORMAT_NV21_ZSL format`          \
    'http://review.cyanogenmod.org/#/c/53344/' `# hwc: Add support to smooth streaming feature.`                     \
    'http://review.cyanogenmod.org/#/c/53345/' `# hwcomposer: Clear mVirtualonExtActive on EXTERNAL_OFFLINE`         \
    'http://review.cyanogenmod.org/#/c/53346/' `# hwc: support 8x26 variants`                                        \
    'http://review.cyanogenmod.org/#/c/53347/' `# libhwcomposer: Optimize layer crops when possible.`                \
    'http://review.cyanogenmod.org/#/c/53348/' `# libexternal: remove mEDIDs string`                                 \
    'http://review.cyanogenmod.org/#/c/53349/' `# libhwcomposer: Make Rect utils generic.`                           \
    'http://review.cyanogenmod.org/#/c/53350/' `# hwc: Fix rotator size allocation to max buffer size`               \
    'http://review.cyanogenmod.org/#/c/53351/' `# overlay: Account for transform in size calculation`                \
    'http://review.cyanogenmod.org/#/c/53352/' `# hwc: Do not punt secure layers for non integral crops`             \
    `# device/samsung/jf-common` \
    `# 'http://review.cyanogenmod.org/#/c/53267/'` `# jf: selinux bringup`                                           \
    'http://review.cyanogenmod.org/#/c/53265/' `# jf: update wifi config`                                            \
    `# 'http://review.cyanogenmod.org/#/c/53266/'` `# jf: remove gsm/cdma overlay dirs`                              \
    'http://review.cyanogenmod.org/#/c/53264/' `# jf: dont build qcom camera HAL`                                    \
    'http://review.cyanogenmod.org/#/c/53372/' `# Fix mounting of external sd`                                       \
    'http://review.cyanogenmod.org/#/c/53373/' `# jf-common: translucent lockscreen decor`                           \
    `# hardware/libhardware` \
    'http://review.cyanogenmod.org/#/c/53072/' `# libhardware: Add APIs to support DirectTrack`                      \
    'http://review.cyanogenmod.org/#/c/53328/' `# libhardware: Add MSM string parameters.`                           \
    `# hardware/libhardware_legacy` \
    'http://review.cyanogenmod.org/#/c/53073/' `# libhardware_legacy: Add MSM specific flags, devices and channels.` \
    'http://review.cyanogenmod.org/#/c/53074/' `# libhardware_legacy: Add support for DirectTrack`                   \
    `# 'http://review.cyanogenmod.org/#/c/53165/'` `# audio_policy: Add EVRCB & EVRCWB formats`                      \
    `# frameworks/av` \
    'http://review.cyanogenmod.org/#/c/53324/' `# frameworks_av: Support pre-KitKat audio blobs`                     \
    `# system/core` \
    'http://review.cyanogenmod.org/#/c/53102/' `# healthd: allow devices to provide their own libhealthd`            \
    'http://review.cyanogenmod.org/#/c/53075/' `# Add back DurationTimer to fix camera.msm8960 load`                 \
    'http://review.cyanogenmod.org/#/c/53310/' `# Add support for QCs time_daemon`                                   \
    `# device/samsung/qcom-common` \
    'http://review.cyanogenmod.org/#/c/53115/' `# qcom: allow properly querying of battery capacity`
}
