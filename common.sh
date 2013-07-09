# Set up environment
common_envsetup() {
  git config --global user.name "$(whoami)"
  git config --global user.email "$(whoami)@${NODE_NAME}"

  # ccache
  export USE_CCACHE=1
  export CCACHE_NLEVELS=4
  export PATH="${PATH}:$(pwd)/prebuilts/misc/$(uname | tr '[A-Z]' '[a-z]')-x86/ccache"
  if [ -z "${CCACHE_DIR}" ]; then
    export CCACHE_DIR=${WORKSPACE}/ccache
  fi
}

# Commands to run before "repo init"
common_preinit() {
  # Remove manifests
  rm -rf .repo/manifests*
  rm -f .repo/local_manifests/dyn-*.xml
}

# Initialize repo
common_repoinit() {
  echo "common_repoinit() must be overridden!"
  exit 1
}

# Commands to run before "repo sync"
common_presync() {
  mkdir -p .repo/local_manifests
  rm -f .repo/local_manifest.xml

  if [ -f "${WORKSPACE}/hudson/manifests/${ROM}_${REPO_BRANCH}.xml" ]; then
    cp "${WORKSPACE}/hudson/manifests/${ROM}_${REPO_BRANCH}.xml" \
      .repo/local_manifests/dyn-${REPO_BRANCH}.xml
  fi
}

# Commands to run after "repo sync"
common_postsync() {
  # Clean up if the branch has changed
  if [ -f .last_branch ]; then
    LAST_BRANCH=$(cat .last_branch)
  else
    echo "Last branch is unknown, assuming that tree is clean"
    LAST_BRANCH=${REPO_BRANCH}
  fi

  if [ "${LAST_BRANCH}" != "${REPO_BRANCH}" ]; then
    echo "Branch has changed, need to clean up"
    CLEAN=true
  fi
}

# Commands to run before build
common_prebuild() {
  . build/envsetup.sh

  # Set up tree for device
  set +e
  lunch ${LUNCH}
  set -e

  # Archive the manifests
  repo manifest -o "${WORKSPACE}/archive/manifest.xml" -r

  if [ ! -z "${CCACHE_SIZE}" ]; then
    ccache -M "${CCACHE_SIZE}"
  fi

  # TODO: Check for changes before building

  # Clean tree every 24 hours or when branch is changed
  LAST_CLEAN=0
  if [ -f .clean ]; then
    LAST_CLEAN=$(date -r .clean +%s)
  fi
  TIME_SINCE_LAST_CLEAN=$(expr $(date +%s) - ${LAST_CLEAN})
  # convert this to hours
  TIME_SINCE_LAST_CLEAN=$(expr ${TIME_SINCE_LAST_CLEAN} / 60 / 60)
  if [ ${TIME_SINCE_LAST_CLEAN} -gt "24" -o ${CLEAN} = "true" ]; then
    echo "Cleaning!"
    touch .clean
    #make clobber
  else
    echo "Skipping clean: ${TIME_SINCE_LAST_CLEAN} hours since last clean."
  fi

  # Save current branch
  echo "${REPO_BRANCH}" > .last_branch
}

common_build() {
  #time mka bacon recoveryzip recoveryimage checkapi
  time mka bacon
}

common_postbuild() {
  rm -f .repo/local_manifests/dyn-${REPO_BRANCH}.xml
  rm -f .repo/local_manifests/roomservice.xml
}

################################################################################

printline() {
  CHAR="${1:0:1}"
  [ -z "${CHAR}" ] && CHAR='-'
  COLS=$(tput cols)
  [ -z "${COLS}" ] && COLS=80
  while [ "${COLS}" -gt 0 ]; do
    echo -n "${CHAR}"
    let COLS--
  done
  echo
}
