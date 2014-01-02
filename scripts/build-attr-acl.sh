#!/bin/bash

set -e

# http://releases.linaro.org/13.12/components/toolchain/gcc-linaro/4.8/gcc-linaro-4.8-2013.12.tar.xz

export GCC_DIR=/home/chenxiaolong/gcc-linaro-arm-linux-gnueabihf-4.8-2013.11_linux/bin

TEMPDIR=$(mktemp -d)
export PATH="${PATH}:${GCC_DIR}"

pushd "${TEMPDIR}"
wget 'http://download.savannah.gnu.org/releases/attr/attr-2.4.47.src.tar.gz'
tar zxvf attr-2.4.47.src.tar.gz

pushd attr-2.4.47/

./configure \
  --host=arm-linux-gnueabihf \
  --build=x86_64-unknown-linux-gnu \
  --prefix=$(readlink -f ../target) \
  --enable-shared \
  --enable-static \
  --disable-lib64 \
  --disable-gettext

make

make install-dev
make install-lib

# libtool doesn't link the libraries statically
pushd getfattr
arm-linux-gnueabihf-gcc \
  -static \
  -o ../../target/getfattr \
  getfattr.o \
  ../libmisc/.libs/libmisc.a \
  ../libattr/.libs/libattr.a
popd

pushd setfattr
arm-linux-gnueabihf-gcc \
  -static \
  -o ../../target/setfattr \
  setfattr.o \
  ../libmisc/.libs/libmisc.a \
  ../libattr/.libs/libattr.a
popd

popd

wget 'http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz'
tar zxvf acl-2.2.52.src.tar.gz

pushd acl-2.2.52

export CFLAGS="-I$(readlink -f ../target)/include"
export LDFLAGS="-L$(readlink -f ../target)/lib"

./configure \
  --host=arm-linux-gnueabihf \
  --build=x86_64-unknown-linux-gnu \
  --prefix=$(readlink -f ../target) \
  --disable-shared \
  --enable-static \
  --disable-lib64 \
  --disable-gettext

make

pushd getfacl
arm-linux-gnueabihf-gcc \
  ${CFLAGS} ${LDFLAGS} \
  -static \
  -o ../../target/getfacl \
  getfacl.o \
  user_group.o \
  ../libmisc/.libs/libmisc.a \
  ../libacl/.libs/libacl.a \
  -lattr
popd

pushd setfacl
arm-linux-gnueabihf-gcc \
  ${CFLAGS} ${LDFLAGS} \
  -static \
  -o ../../target/setfacl \
  setfacl.o \
  do_set.o \
  sequence.o \
  parse.o \
  ../libmisc/.libs/libmisc.a \
  ../libacl/.libs/libacl.a \
  -lattr
popd

popd

pushd target
find -maxdepth 1 -mindepth 1 -type d | xargs rm -rf
arm-linux-gnueabihf-strip getfattr setfattr getfacl setfacl
popd

popd

cp "${TEMPDIR}"/target/{getfattr,setfattr,getfacl,setfacl} .

rm -rf "${TEMPDIR}"
