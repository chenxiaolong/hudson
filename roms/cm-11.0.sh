reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
    'packages/apps/Apollo/'
    'device/samsung/jf-common/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'external/bluetooth/bluedroid/'
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
    `# device/samsung/jf-common`                                      \
    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS` \
    `# packages/apps/Apollo`                                          \
    'http://review.cyanogenmod.org/#/c/54722/'                        \

#    `# Camera stuff` \
#    I26898b82f6c9ab81e6f1681805de229e4ac2f308 \
#    I56739157380f596c9f3bbbe7aecd8f532d619c72 \
#    Ia0f5716d5e6815d249040b08313482a103a36863 \
#    I216502fe032a89f69e1aea11bc50c51634d40991 \
#    Ib36bd21c9a76b45bced3eee2f25acc35b5d82b30
}
