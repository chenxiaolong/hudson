reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
    'packages/apps/Dialer/'
    'packages/apps/ContactsCommon/'
    'packages/apps/InCallUI/'
    'packages/services/Telephony/'
    'frameworks/base/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
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
  popd

  pushd packages/apps/ContactsCommon/
  apply_patch_file_git ${DIALERLOOKUP}/0001-ContactsCommon-Add-extended-directory-for-forward-nu.patch
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

#  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
#    `# device/samsung/jf-common`                                      \
#    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`
}
