arch_checkdeps() {
  NEEDED=('bison'
          'ccache'
          'curl'
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

  if [[ ! -z "${NOTINSTALLED[@]}" ]]; then
    echo "Missing packages: ${NOTINSTALLED[@]}"
    exit 1
  fi
}

arch_envsetup() {
  # JDK and JRE 6 paths
  export PATH="/opt/java6/jre/bin:/opt/java6/bin:${PATH}"

  unset _JAVA_OPTIONS

  mkdir -p "${WORKSPACE}/bin/"
  if [ ! -f "${WORKSPACE}/bin/python" ]; then
    ln -s /usr/bin/python2 "${WORKSPACE}/bin/python"
  fi
}
