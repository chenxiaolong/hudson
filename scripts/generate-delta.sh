#!/bin/bash

if [ -z "${SF_USERNAME}" ] || [ -z "${SF_PROJECT}" ]; then
  echo 'SF_USERNAME and SF_PROJECT need to be set!'
  exit 1
fi

if [ -z "${JOB_DIR}" ]; then
  echo "JOB_DIR needs to be set to the job directory for the 'Android' Jenkins job"
  exit 1
fi

if [ -z "${BINARIES_DIR}" ]; then
  echo "BINARIES_DIR needs to be set to the directory containing zipadjust"
  exit 1
fi

DIR="/home/frs/project/${SF_PROJECT}/Nightlies/${LUNCH}"
SFTP="cd ${DIR}\nls */*.zip"

echo "Getting last two builds from SourceForge for ${LUNCH} ..."
LAST2=($(echo -e "${SFTP}" \
         | sftp ${SF_USERNAME},${SF_PROJECT}@frs.sourceforge.net \
         | grep -v '^sftp>' \
         | sort \
         | tail -n 2 \
         | awk '{print $1}'))

CURRENT="${LAST2[1]}"
LAST="${LAST2[0]}"

if [[ -z "${CURRENT}" ]] || [[ -z "${LAST}" ]]; then
  echo "Less than two latest builds. Cannot create delta."
  exit 0
fi

echo "Latest build:        ${CURRENT}"
echo "Second Latest build: ${LAST}"

cleanup() {
  rm -rf "${OLDDIR}"
  rm -rf "${NEWDIR}"
  rm -rf "${TARGETDIR}"
}

OLDDIR=$(mktemp -d)
NEWDIR=$(mktemp -d)
TARGETDIR=$(mktemp -d)

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

download_file() {
  local URL="https://downloads.sourceforge.net/project/${SF_PROJECT}/Nightlies/${LUNCH}/${1}"
  local DEST="${2}"

  if which axel &>/dev/null; then
    axel -n4 "${URL}" -o ${DEST}
  else
    wget "${URL}" -O ${DEST}
  fi
}

echo "Checking if latest build is available locally ..."
CURRENT_FILENAME=$(basename ${CURRENT})
CURRENT_LOCAL=$(find ${JOB_DIR} -name ${CURRENT_FILENAME})
if [[ -z "${CURRENT_LOCAL}" ]]; then
  echo "Nope. Downloading to temporary directory ..."
  download_file ${CURRENT} ${NEWDIR}/${CURRENT_FILENAME}
else
  echo "Yes. Copying to temporary directory ..."
  cp ${CURRENT_LOCAL} ${NEWDIR}/${CURRENT_FILENAME}
fi

echo "Checking if second latest build is available locally ..."
LAST_FILENAME=$(basename ${LAST})
LAST_LOCAL=$(find ${JOB_DIR} -name ${LAST_FILENAME})
if [[ -z "${LAST_LOCAL}" ]]; then
  echo "Nope. Downloading to temporary directory ..."
  download_file ${LAST} ${OLDDIR}/${LAST_FILENAME}
else
  echo "Yes. Copying to temporary directory ..."
  cp ${LAST_LOCAL} ${OLDDIR}/${LAST_FILENAME}
fi

# Create delta
echo "Downloading latest delta generation script ..."
rm -f opendelta.py
wget -q https://raw.github.com/chenxiaolong/hudson/master/scripts/opendelta.py
python3 opendelta.py ${LUNCH} ${OLDDIR} ${NEWDIR} ${BINARIES_DIR} ${TARGETDIR}
rm -f opendelta.py

if ! (ls ${TARGETDIR}/*.update &>/dev/null \
    && ls ${TARGETDIR}/*delta &>/dev/null); then
  echo "Delta files don't exist. Something must have failed."
  exit 1
fi

echo "Downloading latest SourceForge upload script ..."
rm -f sourceforge-upload.sh
wget -q https://raw.github.com/chenxiaolong/hudson/master/scripts/sourceforge-upload.sh
bash sourceforge-upload.sh UpdateDelta/${LUNCH} ${TARGETDIR}/*.update
bash sourceforge-upload.sh UpdateDelta/${LUNCH} ${TARGETDIR}/*.delta
rm -f sourceforge-upload.sh

exit 0
