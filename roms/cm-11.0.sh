reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
    'frameworks/base/'
    'packages/apps/BluetoothExt/'
    'external/bluetooth/bluedroid/'
    'packages/apps/Bluetooth/'
    'hardware/libhardware/'
    'device/samsung/msm8960-common/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'packages/apps/ContactsCommon/'
    'packages/apps/Dialer/'
    'packages/apps/InCallUI/'
    'packages/services/Telephony/'
  )

  for i in ${RESET_DIRS[@]} ${RESET_DIRS_OLD[@]}; do
    if [ -d "${i}" ]; then
      if [ -d "${i}/.git/refs/remotes/cxl" ]; then
        reset_git_state ${i} cxl/${REPO_BRANCH}
      else
        reset_git_state ${i} github/${REPO_BRANCH}
      fi
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  FACEBOOKSYNC=${PATCHES}/facebook-sync

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# frameworks/base/` \
    'http://review.cyanogenmod.org/#/c/58333/' \
    `# packages/apps/BluetoothExt/` \
    'http://review.cyanogenmod.org/#/c/58303/' \
    `# external/bluetooth/bluedroid/` \
    'http://review.cyanogenmod.org/#/c/58293/' \
    'http://review.cyanogenmod.org/#/c/58294/' \
    'http://review.cyanogenmod.org/#/c/58295/' \
    'http://review.cyanogenmod.org/#/c/58296/' \
    'http://review.cyanogenmod.org/#/c/58297/' \
    `# packages/apps/Bluetooth/` \
    'http://review.cyanogenmod.org/#/c/58298/' \
    'http://review.cyanogenmod.org/#/c/58299/' \
    'http://review.cyanogenmod.org/#/c/58300/' \
    'http://review.cyanogenmod.org/#/c/58301/' \
    `# hardware/libhardware/` \
    'http://review.cyanogenmod.org/#/c/58344/' \
#    `# device/samsung/msm8960-common/` \
#    'http://review.cyanogenmod.org/#/c/57566/'

#  GERRIT_URL="http://gerrit.cxl.epac.to" \
#  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
#    'http://gerrit.cxl.epac.to/#/c/16' \
#    'http://gerrit.cxl.epac.to/#/c/17' \
#    'http://gerrit.cxl.epac.to/#/c/18' \
#    'http://gerrit.cxl.epac.to/#/c/19' \
#    'http://gerrit.cxl.epac.to/#/c/20' \
#    'http://gerrit.cxl.epac.to/#/c/21'
}
