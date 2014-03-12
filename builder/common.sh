################################################################################
# Functions for dealing with functions                                         #
################################################################################

# Check if function exists
funcexists() {
    if declare -f "${1}" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Call function if it exists
callfunc() {
    local func="${1}"
    shift
    if funcexists "${func}"; then
        "${func}" "${@}"
    else
        error "Function ${func} does not exist!"
    fi
}

# Print execution time of command
exectime() {
    local run="${1}"
    shift
    time "${run}" "${@}"
    local ret="${?}"
    echo "^^^ Time spent running ${run} ^^^"
    return "${ret}"
}

################################################################################
# Functions for displaying stuff                                               #
################################################################################

logtag="BUILDER"

info() {
    echo "${logtag}:" "${@}"
}

warning() {
    echo "${logtag}:" "${@}"
}

error() {
    echo "${logtag}:" "${@}" >&2
}

printline() {
    local char="${1:0:1}"
    if [[ "${char-unset}" == "unset" ]]; then
        char="-"
    fi

    local cols=$(tput cols 2>/dev/null || echo 80)
    while [ "${cols}" -gt 0 ]; do
        echo -n "${char}"
        let cols--
    done
    echo
}

display_manifests() {
    printline '='
    echo 'Main manifest:'
    printline '-'
    cat "${romdir}/.repo/manifest.xml"
    printline '='

    local_manifests="$(find "${romdir}"/.repo/local_manifests -name '*.xml' || true)"
    if [[ "${local_manifests+set}" == "set" ]]; then
        for i in ${local_manifests}; do
            printline '='
            echo "${i}"
            printline '-'
            cat "${i}"
            printline '='
        done
    fi
}

################################################################################
# git and patch functions                                                      #
################################################################################

reset_git_state() {
    printline '-'
    info "Resetting ${1} to ${2} ..."

    pushd ${1}

    # Cancel any patch-applying operation
    git am --abort || true

    # Reset to remote branch
    if [[ ! -z "${2}" ]]; then
        if [[ -f ".git/refs/remotes/m/${2}" ]]; then
            git reset --hard "m/${2}"
        else
            warning "Could not find ref for m/${2}"
            git reset --hard HEAD
        fi
    else
        git reset --hard HEAD
    fi

    # Clean up untracked files
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

################################################################################

# Set up environment
common_envsetup() {
    #git config --global user.name "$(whoami)"
    #git config --global user.email "$(whoami)@${NODE_NAME}"

    # ccache
    export USE_CCACHE=1
    export CCACHE_NLEVELS=4
    if [[ "${CCACHE_DIR-unset}" == "unset" ]]; then
        export CCACHE_DIR=${workspace}/ccache
    fi

    # colorization fix in Jenkins
    export CL_RED="\"\033[31m\""
    export CL_GRN="\"\033[32m\""
    export CL_YLW="\"\033[33m\""
    export CL_BLU="\"\033[34m\""
    export CL_MAG="\"\033[35m\""
    export CL_CYN="\"\033[36m\""
    export CL_RST="\"\033[0m\""

    pushd "${workspace}"

    # Clean out old archived files
    rm -rf archive
    mkdir archive

    # Add binaries in workspace to path
    export PATH="$(pwd)/bin:${PATH}"

    # Download repo if it doesn't exist
    if ! which repo &>/dev/null; then
        mkdir -p bin/
        curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > bin/repo
        chmod a+x bin/repo
    fi

    repo="$(which repo)"

    popd
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
    return 1
}

# Commands to run before "repo sync"
common_presync() {
    mkdir -p .repo/local_manifests
    rm -f .repo/local_manifest.xml

    if [ -f "${topdir}/manifests/${rom}_${branch}.xml" ]; then
        cp "${topdir}/manifests/${rom}_${branch}.xml" \
            .repo/local_manifests/dyn-${branch}.xml
    fi
}

common_syncrepos() {
    if [[ "${sync}" == "true" ]]; then
        repo sync -d -c > /dev/null
    else
        info "'repo sync' disabled for this build"
    fi
}

# Commands to run after "repo sync"
common_postsync() {
    local last_branch

    # Clean up if the branch has changed
    if [ -f .last_branch ]; then
        last_branch="$(cat .last_branch)"
    else
        echo "Last branch is unknown, assuming that tree is clean"
        last_branch=${branch}
    fi

    if [ "${last_branch}" != "${branch}" ]; then
        echo "Branch has changed, need to clean up"
        clean=true
    fi
}

# Commands to run before lunch
common_prelunch() {
    set +u
    . build/envsetup.sh
    set -u
}

# Commands to run before build
common_prebuild() {
    # Set up tree for device
    local max=10

    local counter=0
    while [[ "${counter}" -lt "${max}" ]]; do
        set +u
        lunch "${lunch}"
        if [[ "${?}" -eq 0 ]]; then
            set -u
            break
        fi
        set -u
        warning "*** lunch failed. Retrying after 10 seconds... ***"
        sleep 10
        let counter++
    done

    if [ "${counter}" -eq "${max}" ]; then
        error "*** lunch failed after ${max} tries ***"
        return 1
    fi

    # Generate changelog
    if ! python3 "${topdir}/changelog.py" \
            "${device}" "${rom}" "${branch}" "${workspace}"; then
        error "Failed to generate changelog"
        return 1
    fi

    # Cherrypick changes from gerrit
    if [[ "${GERRIT_CHANGES+set}" == "set" ]]; then
        python3 "${topdir}/gerrit_changes.py" ${GERRIT_CHANGES} || return 1
    fi

    # Archive the manifests
    repo manifest -o "${workspace}/archive/manifest.xml" -r

    if [[ "${CCACHE_SIZE+set}" == "set" ]]; then
        ccache -M "${CCACHE_SIZE}"
    fi

    # Clean tree every 24 hours or when branch is changed
    local max_hours=18
    local last_clean=0
    if [ -f .clean ]; then
        last_clean=$(date -r .clean +%s)
    fi
    last_clean=$(expr $(date +%s) - ${last_clean})
    # Convert this to hours
    last_clean=$(expr ${last_clean} / 60 / 60)
    if [[ "${last_clean}" -gt "${max_hours}" ]] || [[ "${clean}" == "true" ]]; then
        info "Cleaning build tree..."
        touch .clean
        make clobber
    else
        info "Minimal clean: ${last_clean} hours since last full clean."
        make installclean
    fi

    # Save current branch
    echo "${branch}" > .last_branch
}

common_build() {
    local targets=(
        'bacon'
        #'recoveryzip'
        #'recoveryimage'
        #'checkapi'
    )

    local threads=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
    schedtool -B -n 1 -e ionice -n 1 make -j${threads} bacon
    return "${?}"
}

common_postbuild() {
    if [[ "${updatecl}" == "true" ]]; then
        mv ${workspace}/changes_${rom}_${branch}_${device}.new \
            ${workspace}/changes_${rom}_${branch}_${device}
    else
        rm ${workspace}/changes_${rom}_${branch}_${device}.new
    fi

    rm -f .repo/local_manifests/dyn-${branch}.xml
    rm -f .repo/local_manifests/roomservice.xml
}
