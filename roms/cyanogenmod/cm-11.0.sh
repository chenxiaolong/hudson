reset_dirs_cm-11.0() {
    reset_dirs=(
        'packages/providers/ContactsProvider/'
    )

    for i in ${reset_dirs[@]}; do
        if [ -d "${i}" ]; then
            reset_git_state ${i} ${branch}
        fi
    done
}

apply_patches_cm-11.0() {
    patches="${topdir}/roms/cyanogenmod/${branch}"
    fbsync="${patches}/facebook-sync"

    pushd packages/providers/ContactsProvider/
    apply_patch_file_git "${fbsync}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch"
    popd

    python3 "${topdir}/gerrit_changes.py" \
        'http://review.cyanogenmod.org/#/c/62152/'
}
