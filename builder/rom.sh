load_rom() {
    if [ -f "${topdir}/roms/${rom}.sh" ]; then
        source "${topdir}/roms/${rom}.sh"
        return 0
    else
        return 1
    fi
}

setdevice() {
    if funcexists "${rom}_setdevice"; then
        "${rom}_setdevice" "${1}"
        return "${?}"
    fi
}

setromopts() {
    if funcexists "${rom}_setromopts"; then
        IFS=',' read -a romopts <<< "${1}"

        for ((i=0; i < "${#romopts[@]}"; i++)); do
            info "Passing argument to ROM script: ${romopts[${i}]}"
        done

        if [[ "${#romopts[@]}" -gt 0 ]]; then
            "${rom}_setromopts" "${romopts[@]}"
            return "${?}"
        fi
    fi
}

listromopts() {
    if funcexists "${rom}_listromopts"; then
        "${rom}_listromopts"
    else
        echo "${rom} has no extra options"
    fi
}

checkprereqs() {
    if funcexists "${rom}_checkprereqs"; then
        "${rom}_checkprereqs"
        return "${?}"
    fi
}

romorcommon() {
    if funcexists "${rom}_${1}"; then
        exectime "${rom}_${1}"
    else
        exectime "common_${1}"
    fi
    return "${?}"
}

envsetup() {
    romorcommon envsetup
    return "${?}"
}

preinit() {
    romorcommon preinit
    return "${?}"
}

repoinit() {
    romorcommon repoinit
    return "${?}"
}

presync() {
    romorcommon presync
    return "${?}"
}

syncrepos() {
    romorcommon syncrepos
    return "${?}"
}

postsync() {
    romorcommon postsync
    return "${?}"
}

prelunch() {
    romorcommon prelunch
    return "${?}"
}

prebuild() {
    romorcommon prebuild
    return "${?}"
}

build() {
    romorcommon build
    return "${?}"
}

postbuild() {
    romorcommon postbuild
    return "${?}"
}
