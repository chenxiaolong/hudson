reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
    'packages/apps/Dialer/'
    'packages/apps/InCallUI/'
    'packages/services/Telephony/'
    'frameworks/base/'
    'packages/apps/BluetoothExt/'
    'external/bluetooth/bluedroid/'
    'packages/apps/Bluetooth/'
    'hardware/libhardware/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'packages/apps/ContactsCommon/'
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
  DIALERLOOKUP=${PATCHES}/dialer-lookup

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  pushd packages/apps/Dialer/
  apply_patch_file_git ${DIALERLOOKUP}/0001-Dialer-Add-support-for-forward-and-reverse-lookups.patch
  popd

  pushd packages/apps/InCallUI/
  apply_patch_file_git ${DIALERLOOKUP}/0001-InCallUI-Add-phone-number-service.patch
  popd

  pushd packages/services/Telephony/
  apply_patch_file_git ${DIALERLOOKUP}/0001-Telephony-Add-settings-for-forward-and-reverse-numbe.patch
  popd

  pushd frameworks/base/
  apply_patch_file_git ${DIALERLOOKUP}/0001-AccountManagerService-Allow-com.android.dialer-to-ac.patch
  apply_patch_file_git ${DIALERLOOKUP}/0001-Frameworks-Add-settings-keys-for-forward-and-reverse.patch
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
    'http://review.cyanogenmod.org/#/c/58344/'
}
