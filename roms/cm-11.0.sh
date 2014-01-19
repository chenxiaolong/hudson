reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'packages/providers/ContactsProvider/'
    'packages/apps/Dialer/'
    'packages/apps/InCallUI/'
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
  GOOGLEDIALER=${PATCHES}/google-dialer

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  pushd packages/apps/Dialer/
  apply_patch_file_git ${GOOGLEDIALER}/0001-Open-source-Google-Dialer.patch
  apply_patch_file_git ${GOOGLEDIALER}/0001-Auto-merge-Google-Dialer-translations.patch
  apply_patch_file_git ${GOOGLEDIALER}/0001-Re-add-LoaderCallbacks-to-CyanogenMod-dialer.patch
  popd

  pushd packages/apps/InCallUI/
  apply_patch_file_git ${GOOGLEDIALER}/0001-InCallUI-Google-Phone-Number-Service.patch
  popd

#  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
#    `# device/samsung/jf-common`                                      \
#    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS`
}
