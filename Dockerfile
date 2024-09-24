FROM centos:7

# https://dev.to/franzwong/fix-cannot-find-a-valid-baseurl-for-repo-in-centos-1h07
RUN sed -i "s/mirrorlist/vault/g; s/#baseurl/baseurl/g; s/mirror/vault/g" /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y centos-release-scl-rh
RUN sed -i "s/mirrorlist/vault/g; s/#baseurl/baseurl/g; s/mirror/vault/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
# devtoolset-11 - GCC 11
RUN yum install -y devtoolset-11
# libuuid-devel - _uuid module (https://stackoverflow.com/q/58709283)
RUN yum install -y bzip2-devel gdbm-devel krb5-devel libcom_err-devel \
                   libffi-devel ncurses-devel readline-devel sqlite-devel \
                   xz-devel zlib-devel libuuid-devel

# Perl is required to build OpenSSL 3
# RUN yum install rh-perl530
RUN yum install -y rh-perl530-perl-Text-Template rh-perl530-perl-IPC-Cmd \
                   rh-perl530-perl-Data-Dumper rh-perl530-perl-Pod-Html

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
