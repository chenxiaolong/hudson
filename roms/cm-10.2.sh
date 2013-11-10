reset_dirs_cm-10.2() {
  RESET_DIRS=('system/vold/'
              'device/samsung/jf-common/'
              'packages/apps/Settings/'
              'frameworks/base/'
              'frameworks/opt/hardware/'
              'hardware/samsung/'
              'external/busybox/'
              'vendor/cm/'
              'system/core/'
              'build/'
              'frameworks/native/'
              'packages/providers/ContactsProvider/')

  for i in ${RESET_DIRS[@]}; do
    if [ -d "${i}" ]; then
      pushd ${i}
      reset_git_state github/${REPO_BRANCH}
      popd
    fi
  done
}

apply_patches_cm-10.2() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  MOVEAPPTOSD=${PATCHES}/move-app-to-sd
  HIGHTOUCHSENSITIVITY=${PATCHES}/high-touch-sensitivity
  DUALBOOT=${PATCHES}/dual-boot
  FACEBOOKSYNC=${PATCHES}/facebook-sync
  GERRIT=${PATCHES}/gerrit
  OMNI=${PATCHES}/omni

  pushd system/vold/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-vold-Allow-ASEC-containers-on-external-SD-when-inter.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Vold-Do-not-mount-ASEC-containers-if-moving-apps-to-.patch
  popd

  pushd device/samsung/jf-common/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Set-externalSd-attribute-for-the-external-SD-card.patch
  apply_patch_file_git ${DUALBOOT}/0001-jf-Add-dual-booting-support.patch
  popd

  pushd packages/apps/Settings/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Enable-moving-applications-to-the-external-SD-card.patch
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Add-preferences-for-high-touch-sensitivity.patch
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Auto-copied-translations-for-high-touch-sensitivity.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-app-moving-setting-to-development-options.patch
  apply_patch_file_git ${GERRIT}/48359/0001-Add-configuraion-for-showing-statusbar-on-top-of-ful.patch
  apply_patch_file_git ${GERRIT}/51228/0001-Add-configuration-for-autounhiding-statusbar-on-new-.patch
  apply_patch_file_git ${OMNI}/1042/PS2_0001-2-2-Setting-for-translucent-statusbar-on-lockscreen.patch
  apply_patch_file_git ${OMNI}/1122/PS2_0001-2-2-Settings-Add-lockscreen-ring-battery-setting.patch
  popd

  pushd frameworks/base/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-changes-for-moving-applications-to-externa.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Framework-Check-of-moving-apps-to-SD-is-disabled.patch
  apply_patch_file_git ${OMNI}/53/PS19_0001-WIP-Multi-window.patch
  apply_patch_file_git ${OMNI}/1041/PS3_0001-1-2-Setting-for-translucent-statusbar-on-lockscreen.patch
  apply_patch_file_git ${OMNI}/1062/PS12_0001-1-2-Add-battery-level-around-unlock-ring.patch
  apply_patch_file_git ${OMNI}/59/PS1_0001-SystemUI-Translucent-status-bar-on-lockscreen.patch
  apply_patch_file_git ${GERRIT}/51084/PS5_0001-PieService-add-support-for-multiple-activations.patch
  apply_patch_file_git ${GERRIT}/51229/PS1_0001-Allow-auto-unhiding-statusbar-when-new-notification-.patch
  apply_patch_file_git ${GERRIT}/48352/PS20_0001-Allow-showing-statusbar-on-top-of-fullscreen-window.patch
  popd

  pushd frameworks/opt/hardware/
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Hardware-Add-high-touch-sensitivity-support.patch
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Add-class-for-enabling-and-disabling-moving-apps-to-.patch
  popd

  pushd hardware/samsung/
  apply_patch_file_git ${HIGHTOUCHSENSITIVITY}/0001-Samsung-add-support-for-high-touch-sensitivity.patch
  popd

  pushd external/busybox/
  apply_patch_file_git ${DUALBOOT}/0001-Busybox-Include-in-boot-image.patch
  popd

  pushd vendor/cm/
  apply_patch_file_git ${DUALBOOT}/0001-Add-helper-script-for-dual-boot-detection-in-updater.patch
  popd

  pushd system/core/
  apply_patch_file_git ${DUALBOOT}/0001-init.rc-Dual-boot-preparation.patch
  popd

  pushd build/
  apply_patch_file_git ${DUALBOOT}/0001-Allow-dual-boot-installation-in-updater-script.patch
  popd

  pushd frameworks/native/
  apply_patch_file_git ${MOVEAPPTOSD}/0001-Calculate-application-sizes-correctly.patch
  popd

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  GERRIT_URL="http://review.cyanogenmod.org" \
  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# Native screen sharing API` \
    'http://review.cyanogenmod.org/#/c/50449/' \
    `# Swipe to show statusbar` \
    `# 'http://review.cyanogenmod.org/#/c/51084/' # Patch fixed manually` \
    `# 'http://review.cyanogenmod.org/#/c/51229/' # Patch fixed manually` \
    `# 'http://review.cyanogenmod.org/#/c/51228/' # Patch fixed manually` \
    `# 'http://review.cyanogenmod.org/#/c/48359/' # Patch fixed manually` \
    `# 'http://review.cyanogenmod.org/#/c/48352/' # Patch fixed manually` \
    || echo '*** FAILED TO APPLY PATCHES ***'

  #GERRIT_URL="https://gerrit.omnirom.org" \
  #python3 ${WORKSPACE}/hudson/gerrit_changes.py \
  #  `# Lock screen battery ring` \
  #  'https://gerrit.omnirom.org/#/c/1062/' \
  #  || echo '*** FAILED TO APPLY PATCHES ***'
}
