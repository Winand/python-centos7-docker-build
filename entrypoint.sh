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
./config --prefix=$INSTALL_PATH && make && make install
popd

VERSION="${PYTHON_VERSION:-3.12.0}"
curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz && tar xf Python-$VERSION.tar.xz && pushd Python-$VERSION
./configure --enable-optimizations --prefix=$INSTALL_PATH --with-openssl=$INSTALL_PATH --with-openssl-rpath=auto
make
make altinstall
popd

tar cfz output/python_${PYTHON_VERSION}_centos7.tar.gz $INSTALL_PATH
