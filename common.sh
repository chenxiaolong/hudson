# Set up environment
common_envsetup() {
  #git config --global user.name "$(whoami)"
  #git config --global user.email "$(whoami)@${NODE_NAME}"

  # ccache
  export USE_CCACHE=1
  export CCACHE_NLEVELS=4
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

# Commands to run before lunch
common_prelunch() {
  . build/envsetup.sh
}

# Commands to run before build
common_prebuild() {
  set +e

  # Set up tree for device
  COUNTER=0
  while [ "${COUNTER}" -lt 10 ]; do
    lunch ${LUNCH}
    if [ "${?}" -eq 0 ]; then
      break
    fi
    echo "*** LUNCH FAILED. RETRYING AFTER 10 SECONDS ... ***"
    sleep 10
    let COUNTER++
  done

  if [ "${COUNTER}" -eq 3 ]; then
    echo "*** LUNCH FAILED AFTER 10 TRIES ***"
    exit 1
  fi

  # Generate changelog
  if ! python3 ${WORKSPACE}/hudson/changelog.py ${LUNCH_OLD} ${ROM} ${REPO_BRANCH}; then
    exit 2
  fi

  # Cherrypick changes from gerrit
  if [[ ! -z "${GERRIT_CHANGES}" ]]; then
    python3 ${WORKSPACE}/hudson/gerrit_changes.py ${GERRIT_CHANGES}
  fi

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
###
#  TIME_SINCE_LAST_CLEAN=1
###
  if [ "${TIME_SINCE_LAST_CLEAN}" -gt "24" -o "${CLEAN}" = "true" ]; then
    echo "Cleaning!"
    touch .clean
    set -e
    make clobber
    set +e
  else
    echo "Skipping clean: ${TIME_SINCE_LAST_CLEAN} hours since last clean."
  fi

  # Save current branch
  echo "${REPO_BRANCH}" > .last_branch

  set -e
}

common_build() {
  #time mka bacon recoveryzip recoveryimage checkapi
  #time mka bacon
  THREADS=$(cat /proc/cpuinfo | grep "^processor" | wc -l)

  case "${MAKECORES}" in
  DOUBLE)
    THREADS=$(lscpu -p=core,socket | grep -v '#' | uniq | wc -l)
    THREADS=$((${THREADS}*2))
    ;;
  PLUSONE)
    THREADS=$(lscpu -p=core,socket | grep -v '#' | uniq | wc -l)
    THREADS=$((${THREADS}+1))
    ;;
  DEFAULT)
    ;;
  *)
    ;;
  esac

  if [ "x${DISTRO}" = "xubuntu" ]; then
    time schedtool -B -n 1 -e ionice -n 1 make -j${THREADS} bacon
  else
    time schedtool -B -n -10 -e ionice -n 1 make -j${THREADS} bacon
  fi
}

common_postbuild() {
  if [ "x${UPDATE_TIMESTAMP}" = "xtrue" ]; then
    mv ${WORKSPACE}/changes_${ROM}_${REPO_BRANCH}_${LUNCH_OLD}.new \
       ${WORKSPACE}/changes_${ROM}_${REPO_BRANCH}_${LUNCH_OLD}
  else
    rm ${WORKSPACE}/changes_${ROM}_${REPO_BRANCH}_${LUNCH_OLD}.new
  fi

  rm -f .repo/local_manifests/dyn-${REPO_BRANCH}.xml
  rm -f .repo/local_manifests/roomservice.xml
}

################################################################################

printline() {
  CHAR="${1:0:1}"
  [ -z "${CHAR}" ] && CHAR='-'
  COLS=$(tput cols 2>/dev/null || echo 80)
  while [ "${COLS}" -gt 0 ]; do
    echo -n "${CHAR}"
    let COLS--
  done
  echo
}

reset_git_state() {
  printline '-'
  echo "Resetting ${1} to ${2} ..."
  pushd ${1}
  git am --abort || true
  if ! [ -z "${2}" ]; then
    if grep -q '/' <<< ${2}; then
      if [ -f .git/refs/remotes/${2} ]; then
        git reset --hard "${2}"
      elif [ -f .git/refs/remotes/${2/github/m} ]; then
        # Hack
        git reset --hard "${2/github/m}"
      else
        echo "ERROR: Could not find ref for ${2}"
        git reset --hard
      fi
    else
      git reset --hard
    fi
  else
    git reset --hard
  fi
  git clean -fdx
  popd
  printline '-'
}

apply_patch_file_git() {
  printline '-'
  echo "Applying ${1} (with git) ..."
  git am "${1}" || {
    git am --abort
    echo "Failed to apply ${1}"
    exit 1
  }
  printline '-'
}

apply_patch_file() {
  printline '-'
  echo "Applying ${1} ..."
  patch -p1 -i "${1}" || {
    reset_git_state
    echo "Failed to apply ${1}"
    exit 1
  }
  printline '-'
}
