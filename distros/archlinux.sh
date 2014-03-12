distros+=('arch')

arch_isdistro() {
    if [ -f /etc/arch-release ]; then
        return 0
    else
        return 1
    fi
}

arch_checkdeps() {
    NEEDED=('bison'
            'ccache'
            'flex'
            'gcc-multilib'
            'git'
            'gnupg'
            'gperf'
            'lib32-zlib'
            'lib32-ncurses'
            'lib32-readline'
            'libxslt'
            'ncurses'
            'schedtool'
            'perl-switch'
            'python'
            'sdl'
            'squashfs-tools'
            'unzip'
            'wxgtk'
            'zip'
            'zlib')

    NOTINSTALLED=()
    for i in ${NEEDED[@]}; do
        if [[ "$(pacman -Qq ${i})" != "${i}" ]]; then
        NOTINSTALLED+=("${i}")
        fi
    done

    if [[ "${#NOTINSTALLED[@]}" -gt 0 ]]; then
        echo "Missing packages: ${NOTINSTALLED[@]}"
        exit 1
    fi
}

arch_envsetup() {
    # JDK and JRE 6 paths
    export PATH="/opt/java6/jre/bin:/opt/java6/bin:${PATH}"
    export JAVA_HOME="/opt/java6"

    unset _JAVA_OPTIONS

    mkdir -p "${workspace}/bin/"
    if [ ! -f "${workspace}/bin/python" ]; then
        ln -s /usr/bin/python2 "${workspace}/bin/python"
    fi
}
