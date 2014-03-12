detect_distro() {
    distro=""
    distros=()

    for i in "${topdir}"/distros/*.sh; do
        source "${i}"
    done

    for i in "${distros[@]}"; do
        if ${i}_isdistro; then
            distro="${i}"
            break
        fi
    done

    if [[ -z "${distro}" ]]; then
        return 1
    else
        return 0
    fi
}
