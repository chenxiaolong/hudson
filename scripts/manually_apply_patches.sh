#!/bin/bash

if ! [ "${#}" -eq 2 ]; then
  echo "Usage: ${0} [workspace directory] [branch]"
  exit 1
fi

export REPO_BRANCH="${2}"
export WORKSPACE="${1}"

source ${WORKSPACE}/hudson/common.sh
source ${WORKSPACE}/hudson/roms/${REPO_BRANCH}.sh

reset_dirs_${REPO_BRANCH}
apply_patches_${REPO_BRANCH}
