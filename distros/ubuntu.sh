ubuntu_checkdeps() {
  # There are quite a few that can be removed from this list
  NEEDED=('ccache'
          'git-core'
          'gnupg'
          'flex'
          'bison'
          'gperf'
          'build-essential'
          'zip'
          'curl'
          'zlib1g-dev'
          'zlib1g-dev:i386'
          'libc6-dev'
          'lib32ncurses5'
          'lib32z1'
          'lib32bz2-1.0'
          'lib32ncurses5-dev'
          'x11proto-core-dev'
          'libx11-dev:i386'
          'libreadline6-dev:i386'
          'lib32z-dev'
          'libgl1-mesa-glx:i386'
          'libgl1-mesa-dev'
          'g++-multilib'
          'mingw32'
          'tofrodos'
          'python-markdown'
          'libxml2-utils'
          'xsltproc'
          'readline-common'
          'libreadline6-dev'
          'libreadline6'
          'lib32readline-gplv2-dev'
          'libncurses5-dev'
          'lib32readline5'
          'lib32readline6'
          'libreadline-dev'
          'libreadline6-dev:i386'
          'libreadline6:i386'
          'bzip2'
          'libbz2-dev'
          'libbz2-1.0'
          'libghc-bzlib-dev'
          'lib32bz2-dev'
          'libsdl1.2-dev'
          'libesd0-dev'
          'squashfs-tools'
          'pngcrush'
          'schedtool'
          'libwxgtk2.8-dev'
          'python'
          'oracle-java6-installer')

  NOTINSTALLED=()
  for i in ${NEEDED[@]}; do
    if ! dpkg-query -l ${i} &>/dev/null; then
      NOTINSTALLED+=("${i}")
    fi
  done

  if [[ ! -z "${NOTINSTALLED[@]}" ]]; then
    echo "Missing packages: ${NOTINSTALLED[@]}"
    exit 1
  fi
}
