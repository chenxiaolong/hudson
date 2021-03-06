cyanogenmod_setdevice() {
    export lunch="cm_${1}-userdebug"
}

cyanogenmod_setromopts() {
    for arg in "${@}"; do
        key="${arg%=*}"
        value="${arg#*=}"

        if [[ "${key}" == "releasetype" ]]; then
            cm_releasetype="${value}"
        elif [[ "${key}" == "extraversion" ]]; then
            cm_extraversion="${value}"
        else
            error "Unrecognized ROM argument: ${key}"
            return 1
        fi
    done
}

cyanogenmod_listromopts() {
    echo "releasetype  - One of RELEASE, NIGHTLY, SNAPSHOT, or EXPERIMENTAL"
    echo "extraversion - Extra string to append to the version"
}

cyanogenmod_checkprereqs() {
    if [[ "${cm_releasetype-unset}" == "unset" ]]; then
        warning "CyanogenMod ROM argument 'releasetype' was not set. Defaulting to 'experimental'"
        cm_releasetype="EXPERIMENTAL"
    fi


    if [[ "${cm_releasetype}" != "RELEASE" ]] \
            && [[ "${cm_releasetype}" == "NIGHTLY" ]] \
            && [[ "${cm_releasetype}" == "SNAPSHOT" ]] \
            && [[ "${cm_releasetype}" == "EXPERIMENTAL" ]]; then
        error "Unrecognized value for 'releasetype': ${cm_releasetype}"
        return 1
    fi

    export CM_BUILDTYPE="${cm_releasetype}"

    if [[ "${cm_extraversion+set}" == "set" ]]; then
        export CM_EXTRAVERSION="${cm_extraversion}"
    fi

    info "CyanogenMod release type: ${cm_releasetype}"
    info "CyanogenMod version string: ${cm_extraversion-(none)}"
}

cyanogenmod_envsetup() {
    common_envsetup || return "${?}"

    export BUILD_WITH_COLORS=0

    export GERRIT_URL="http://review.cyanogenmod.org"

    source "${topdir}/roms/cyanogenmod/${branch}.sh"
}

cyanogenmod_presync() {
    common_presync || return "${?}"

    reset_dirs_${branch}
}

cyanogenmod_repoinit() {
    repo init -u https://github.com/chenxiaolong/CM_android.git -b ${branch}
}

cyanogenmod_prebuild() {
    common_prebuild || return "${?}"

    # Remove old zips
    rm -f "${OUT}"/cm-*.zip*

    apply_patches_${branch}

    if [[ "${CM_NIGHTLY+set}" == "set" ]]; then
        make update-api
    fi

    vendor/cm/get-prebuilts
}

cyanogenmod_postbuild() {
    common_postbuild || return "${?}"

    for i in "${OUT}"/cm-*.zip*; do
        ln "${i}" "${workspace}/archive/"
    done

    unzip -p "${OUT}"/cm-*.zip system/build.prop > "${workspace}/archive/build.prop"
}
