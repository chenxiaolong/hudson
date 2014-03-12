slimroms_setdevice() {
    export lunch="slim_${1}-userdebug"
}

slimroms_envsetup() {
    common_envsetup || return "${?}"

    export BUILD_WITH_COLORS=0

    export GERRIT_URL="http://gerrit.slimroms.net"
}

slimroms_repoinit() {
    repo init -u git://github.com/SlimRoms/platform_manifest.git -b ${branch}
}

slimroms_prebuild() {
    common_prebuild || return "${?}"

    # Remove old zips
    rm -f "${OUT}"/[Ss]lim*.zip*
}

slimroms_postbuild() {
    common_postbuild || return "${?}"

    for i in "${OUT}"/Slim-*.zip*; do
        ln "${i}" "${workspace}/archive/"
    done

    unzip -p "${OUT}"/Slim-*.zip system/build.prop > "${workspace}/archive/build.prop"
}
