reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'packages/apps/ContactsCommon/'
    'packages/apps/Dialer/'
    'packages/apps/InCallUI/'
    'packages/services/Telephony/'
    'frameworks/base/'
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

#  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
#    `# device/samsung/jf-common`                                      \
#    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`
}
