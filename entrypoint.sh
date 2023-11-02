#!/bin/bash

# https://austindewey.com/2019/03/26/enabling-software-collections-binaries-on-a-docker-image/
# https://stackoverflow.com/questions/16631461/scl-enable-python27-bash
# `scl enable devtoolset-11 bash` works in interactive terminal only
source scl_source enable devtoolset-11

INSTALL_PATH="${INSTALL_PATH?}"
mkdir -p $INSTALL_PATH
mkdir -p ~/build/output
cd ~/build

OPENSSL_VERSION="${OPENSSL_VERSION:-1.1.1w}"
curl -O https://ftp.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz && tar xzf openssl-$OPENSSL_VERSION.tar.gz && pushd openssl-$OPENSSL_VERSION
./config --prefix=$INSTALL_PATH && make && make install_sw  # install w/o docs https://stackoverflow.com/q/47136654
popd

VERSION="${PYTHON_VERSION:-3.12.0}"
curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz && tar xf Python-$VERSION.tar.xz && pushd Python-$VERSION
# https://docs.python.org/3/using/configure.html#cmdoption-without-static-libpython
# Sort versions https://stackoverflow.com/a/4024263
[ "3.10.0" = "`echo $PYTHON_VERSION 3.10.0 | xargs -n1 | sort -V | head -n1`" ] && \
    WO_STATIC="--without-static-libpython"
./configure --enable-optimizations $WO_STATIC --prefix=$INSTALL_PATH --with-openssl=$INSTALL_PATH --with-openssl-rpath=auto
make
make altinstall
popd

# https://www.cyberciti.biz/faq/how-to-find-and-delete-directory-recursively-on-linux-or-unix-like-system/
find $INSTALL_PATH -type d -name __pycache__ -exec rm -rf {} +
tar cfz output/python_${PYTHON_VERSION}_centos7.tar.gz $INSTALL_PATH
