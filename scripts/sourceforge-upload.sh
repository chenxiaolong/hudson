#!/bin/bash

if [ -z "${SF_USERNAME}" ] || [ -z "${SF_PROJECT}" ]; then
  echo 'SF_USERNAME and SF_PROJECT need to be set!'
  exit 1
fi

UPLOAD_DIR=${1}
shift
UPLOAD_FILES=()

for i in ${@}; do
  UPLOAD_FILES+=(${i})
done

# Create directories
TEMP="/home/frs/project/${SF_PROJECT}"
SFTP=""
for i in $(echo ${UPLOAD_DIR} | tr '/' '\n'); do
  TEMP="${TEMP}/${i}"
  SFTP="${SFTP}mkdir ${TEMP}\n"
done

echo -e "${SFTP}" | sftp ${SF_USERNAME},${SF_PROJECT}@frs.sourceforge.net || true


# Upload
for i in ${UPLOAD_FILES[@]}; do
  echo "Uploading ${i} to ${UPLOAD_DIR} ..."

  COUNTER=0
  while [ "${COUNTER}" -lt 3 ]; do
    rsync -e ssh -avP ${i} ${SF_USERNAME}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${UPLOAD_DIR}
    if [ "${?}" -eq 0 ]; then
      break
    fi
    echo "*** FAILED TO UPLOAD ${i}. RETRYING ... ***"
    let COUNTER++
  done

  if [ "${COUNTER}" -eq 3 ]; then
    echo "*** FAILED TO UPLOAD ${i} AFTER 3 TRIES ***"
    exit 1
  fi
done
