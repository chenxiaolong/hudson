apply_patches_cm-11.0() {
  RESET_DIRS=('hardware/qcom/media-caf/'
              'hardware/qcom/audio-caf/'
              'hardware/qcom/display-caf/'
              'hardware/libhardware/'
              'hardware/libhardware_legacy/'
              'frameworks/av/'
              'system/core/'
              'device/samsung/jf-common/'
              'device/samsung/msm8960-common/'
              'art/')

  for i in ${RESET_DIRS[@]}; do
    if [ -d "${i}" ]; then
      pushd ${i}
      reset_git_state github/${REPO_BRANCH}
      popd
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  JF=${PATCHES}/jf

  pushd device/samsung/jf-common
  apply_patch_file_git ${JF}/0001-Set-SELinux-to-permissive-mode.patch
  apply_patch_file_git ${JF}/0001-Remove-IRDA-for-now.patch
  apply_patch_file_git ${JF}/0001-Comment-out-non-existent-overlays.patch
  apply_patch_file_git ${JF}/0001-Do-not-mount-apnhlos-or-mdm-under-a-SELinux-context.patch
  apply_patch_file_git ${JF}/0001-Enable-translucent-lockscreen-decor.patch
  apply_patch_file_git ${JF}/0001-Fix-SD-card-mounting.patch
  popd

  pushd device/samsung/msm8960-common
  apply_patch_file_git ${JF}/0001-neon-vfpv4-neon.patch
  popd

  pushd art
  apply_patch_file_git ${PATCHES}/0001-Run-generate-operator-out.py-with-Python-2.patch
  popd

  GERRIT_URL="http://review.cyanogenmod.org" \
  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# hardware/qcom/media-caf` \
    'http://review.cyanogenmod.org/#/c/53030/' \
    'http://review.cyanogenmod.org/#/c/53031/' \
    'http://review.cyanogenmod.org/#/c/53032/' \
    'http://review.cyanogenmod.org/#/c/53033/' \
    'http://review.cyanogenmod.org/#/c/53034/' \
    'http://review.cyanogenmod.org/#/c/53035/' \
    `# hardware/qcom/audio-caf` \
    `# 'http://review.cyanogenmod.org/#/c/52997/'` \
    'http://review.cyanogenmod.org/#/c/53194/' \
    'http://review.cyanogenmod.org/#/c/53195/' \
    `# 'http://review.cyanogenmod.org/#/c/53023/'` \
    `# 'http://review.cyanogenmod.org/#/c/53166/'` \
    'http://review.cyanogenmod.org/#/c/53196/' \
    `# hardware/qcom/display-caf` \
    'http://review.cyanogenmod.org/#/c/53337/' \
    'http://review.cyanogenmod.org/#/c/53338/' \
    'http://review.cyanogenmod.org/#/c/53339/' \
    'http://review.cyanogenmod.org/#/c/53340/' \
    'http://review.cyanogenmod.org/#/c/53341/' \
    'http://review.cyanogenmod.org/#/c/53342/' \
    'http://review.cyanogenmod.org/#/c/53343/' \
    'http://review.cyanogenmod.org/#/c/53344/' \
    'http://review.cyanogenmod.org/#/c/53345/' \
    'http://review.cyanogenmod.org/#/c/53346/' \
    'http://review.cyanogenmod.org/#/c/53347/' \
    'http://review.cyanogenmod.org/#/c/53348/' \
    'http://review.cyanogenmod.org/#/c/53349/' \
    'http://review.cyanogenmod.org/#/c/53350/' \
    'http://review.cyanogenmod.org/#/c/53351/' \
    'http://review.cyanogenmod.org/#/c/53352/' \
    `# device/samsung/jf-common` \
    `# 'http://review.cyanogenmod.org/#/c/53267/'` \
    'http://review.cyanogenmod.org/#/c/53265/' \
    `# 'http://review.cyanogenmod.org/#/c/53266/'` \
    'http://review.cyanogenmod.org/#/c/53264/' \
    `# hardware/libhardware` \
    'http://review.cyanogenmod.org/#/c/53072/' \
    'http://review.cyanogenmod.org/#/c/53328/' \
    `# hardware/libhardware_legacy` \
    'http://review.cyanogenmod.org/#/c/53073/' \
    'http://review.cyanogenmod.org/#/c/53074/' \
    `# 'http://review.cyanogenmod.org/#/c/53165/'` \
    `# frameworks/av` \
    'http://review.cyanogenmod.org/#/c/53324/' \
    `# system/core` \
    'http://review.cyanogenmod.org/#/c/53102/' \
    || echo '*** FAILED TO APPLY PATCHES ***'
}
