#!/bin/bash

# https://austindewey.com/2019/03/26/enabling-software-collections-binaries-on-a-docker-image/
# https://stackoverflow.com/questions/16631461/scl-enable-python27-bash
# `scl enable devtoolset-11 bash` works in interactive terminal only
source scl_source enable devtoolset-11
# Perl is required to build OpenSSL 3
source scl_source enable rh-perl530

VERSION="${PYTHON_VERSION?}"
OPENSSL_VERSION="${OPENSSL_VERSION:-1.1.1w}"
INSTALL_PATH="${INSTALL_PATH?}"
SSL_INSTALL_PATH=$INSTALL_PATH/openssl-$OPENSSL_VERSION
SQLITE_INSTALL_PATH=$INSTALL_PATH/sqlite-$SQLITE_VERSION

mkdir -p $INSTALL_PATH
mkdir -p ~/build/output
cd ~/build

INSTALL_PATH_HASH=$(echo -n $INSTALL_PATH | md5sum | cut -f1 -d" ")
if [ -f "output/.cache/$INSTALL_PATH_HASH/openssl-$OPENSSL_VERSION.tar.gz" ]; then
    tar xfz output/.cache/$INSTALL_PATH_HASH/openssl-$OPENSSL_VERSION.tar.gz -C /
else
    OPENSSL_URL=https://openssl.org/source/old/$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz
    # Sort versions https://stackoverflow.com/a/4024263
    [ "3.0.0" = "`echo $OPENSSL_VERSION 3.0.0 | xargs -n1 | sort -V | head -n1`" ] && \
        OPENSSL_URL=https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz
    curl -LO $OPENSSL_URL && tar xzf openssl-$OPENSSL_VERSION.tar.gz && pushd openssl-$OPENSSL_VERSION
    ./config --prefix=$SSL_INSTALL_PATH
    make -j8
    make install_sw  # install w/o docs https://stackoverflow.com/q/47136654
    popd
    # Save to .cache folder
    mkdir -p output/.cache/$INSTALL_PATH_HASH
    tar cfz output/.cache/$INSTALL_PATH_HASH/openssl-$OPENSSL_VERSION.tar.gz $SSL_INSTALL_PATH
fi

# https://www.webdesignsun.com/insights/upgrading-sqlite-on-centos
if [ -n "$SQLITE_VERSION" ]; then
    if [ -f "output/.cache/$INSTALL_PATH_HASH/sqlite-$SQLITE_VERSION.tar.gz" ]; then
        tar xfz output/.cache/$INSTALL_PATH_HASH/sqlite-$SQLITE_VERSION.tar.gz -C /
    else
        curl -LOJ https://github.com/sqlite/sqlite/archive/refs/tags/version-$SQLITE_VERSION.tar.gz
        tar xzf sqlite-version-$SQLITE_VERSION.tar.gz && pushd sqlite-version-$SQLITE_VERSION
        ./configure --prefix=$SQLITE_INSTALL_PATH
        make -j8
        make install
        popd
        # Save to .cache folder
        mkdir -p output/.cache/$INSTALL_PATH_HASH
        tar cfz output/.cache/$INSTALL_PATH_HASH/sqlite-$SQLITE_VERSION.tar.gz $SQLITE_INSTALL_PATH
    fi
elif [ "3.13.0" = "`echo $VERSION 3.13.0 | xargs -n1 | sort -V | head -n1`" ]; then
    echo "Error: building SQLite is required for CPython 3.13+ on CentOS 7" >&2
    exit 1
fi

curl -O https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz && tar xf Python-$VERSION.tar.xz && pushd Python-$VERSION
# https://docs.python.org/3/using/configure.html#cmdoption-without-static-libpython
./configure --help | grep -q -e --without-static-libpython && NO_STATICLIB="--without-static-libpython"
./configure --help | grep -q -e --disable-test-modules && NO_TESTMOD="--disable-test-modules"
if [ -n "$NO_GIL" ]; then
    if ! ./configure --help | grep -q -e --disable-gil; then
        echo "Error: --disable-gil option not found" >&2
        exit 1
    fi
    NO_GIL="--disable-gil"
fi

# https://github.com/python/cpython/issues/121992 OpenSSL 3 uses lib64 folder
if [ -f "$SSL_INSTALL_PATH/lib/pkgconfig/openssl.pc" ]; then
    LIB_SSL=lib
elif [ -f "$SSL_INSTALL_PATH/lib64/pkgconfig/openssl.pc" ]; then
    LIB_SSL=lib64
else
    echo "Error: openssl.pc not found in either lib64 or lib" >&2
    exit 1
fi
# Python 3.10+ with-openssl-rpath https://github.com/python/cpython/issues/87632
# ./configure --help | grep -q -e --with-openssl-rpath \
#     && SSL_RPATH="--with-openssl-rpath=auto" \
#     || SSL_RPATH="LDFLAGS=-Wl,-rpath=$SSL_INSTALL_PATH/$LIB_SSL"
RPATH=$SSL_INSTALL_PATH/$LIB_SSL
# https://discuss.python.org/t/should-values-for-libsqlite3-libs-be-prefixed-by-l-or-not/57495/10
[ -n "$SQLITE_VERSION" ] && RPATH+=:$SQLITE_INSTALL_PATH/lib

PKG_CONFIG_PATH=$SSL_INSTALL_PATH/$LIB_SSL/pkgconfig
[ -n "$SQLITE_VERSION" ] && PKG_CONFIG_PATH+=:$SQLITE_INSTALL_PATH/lib/pkgconfig

./configure --enable-optimizations $NO_STATICLIB $NO_TESTMOD --prefix=$INSTALL_PATH \
            $NO_GIL LDFLAGS=-Wl,-rpath=$RPATH PKG_CONFIG_PATH=$PKG_CONFIG_PATH
make -j8
make altinstall
popd

# https://www.cyberciti.biz/faq/how-to-find-and-delete-directory-recursively-on-linux-or-unix-like-system/
find $INSTALL_PATH -type d -name __pycache__ -exec rm -rf {} +
find $INSTALL_PATH -type d -name include -exec rm -rf {} +
find $INSTALL_PATH -name "*.a" -type f -delete
tar cfz output/python${NO_GIL+t}_${PYTHON_VERSION}_centos7_ssl$OPENSSL_VERSION.tar.gz $INSTALL_PATH
