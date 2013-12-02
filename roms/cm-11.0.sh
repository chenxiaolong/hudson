reset_dirs_cm-11.0() {
  RESET_DIRS=(
    'device/samsung/jf-common/'
    'packages/providers/ContactsProvider/'
    'packages/apps/ScreenRecorder/'
    'kernel/samsung/jf/'
  )

  # Directories that should be reset for one more build
  RESET_DIRS_OLD=(
    'frameworks/opt/telephony/'
    'vendor/cm/'
    'bionic/'
  )

  for i in ${RESET_DIRS[@]} ${RESET_DIRS_OLD[@]}; do
    if [ -d "${i}" ]; then
      if [ -d "${i}/.git/refs/remotes/cxl" ]; then
        reset_git_state ${i} cxl/${REPO_BRANCH}
      else
        reset_git_state ${i} github/${REPO_BRANCH}
      fi
    fi
  done
}

apply_patches_cm-11.0() {
  PATCHES=${WORKSPACE}/hudson/roms/${REPO_BRANCH}
  FACEBOOKSYNC=${PATCHES}/facebook-sync
  DUALBOOT=${PATCHES}/dual-boot

  pushd packages/providers/ContactsProvider/
  apply_patch_file_git ${FACEBOOKSYNC}/0001-ContactsProvider-Hack-to-enable-Facebook-contacts-sy.patch
  popd

  pushd packages/apps/ScreenRecorder/
  git pull --no-edit http://review.chameleonos.org/ChameleonOS/android_packages_apps_ScreenRecorder refs/changes/30/2730/1
  popd

  pushd device/samsung/jf-common/
  cat >> BoardConfigCommon.mk << EOF
# Adreno
OVERRIDE_RS_DRIVER := libRSDriver_adreno.so
HAVE_ADRENO_SOURCE := false
EOF

  cat >> jf-common.mk << EOF
# Sensors
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \\
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \\
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \\
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml
EOF

  git commit -am "blob stuff"
  popd

  python3 ${WORKSPACE}/hudson/gerrit_changes.py \
    `# device/samsung/jf-common`                                      \
    'http://review.cyanogenmod.org/#/c/53635/' `# jf-common: Fix GPS` \
    'http://review.cyanogenmod.org/#/c/53969/' `# jf: fix fstab`      \
    `# bionic`                                                        \
    `# 'http://review.cyanogenmod.org/#/c/54822/'`                    \
    `# kernel/samsung/jf`                                             \
    'http://review.cyanogenmod.org/#/c/54920/'                        \
    'http://review.cyanogenmod.org/#/c/54921/'                        \
    'http://review.cyanogenmod.org/#/c/54922/'                        \
    'http://review.cyanogenmod.org/#/c/54923/'                        \
    'http://review.cyanogenmod.org/#/c/54924/'                        \
    'http://review.cyanogenmod.org/#/c/54925/'                        \
    'http://review.cyanogenmod.org/#/c/54926/'                        \
    'http://review.cyanogenmod.org/#/c/54927/'                        \
    'http://review.cyanogenmod.org/#/c/54928/'                        \
    'http://review.cyanogenmod.org/#/c/54929/'                        \
    'http://review.cyanogenmod.org/#/c/54962/'

#    `# Camera stuff` \
#    I26898b82f6c9ab81e6f1681805de229e4ac2f308 \
#    I56739157380f596c9f3bbbe7aecd8f532d619c72 \
#    Ia0f5716d5e6815d249040b08313482a103a36863 \
#    I216502fe032a89f69e1aea11bc50c51634d40991 \
#    Ib36bd21c9a76b45bced3eee2f25acc35b5d82b30

  pushd device/samsung/jf-common/
  apply_patch_file_git ${DUALBOOT}/0001-jf-Add-dual-booting-support.patch
  popd
}
