FROM centos:7

ARG USER
ARG HOMEROOT
ARG INSTALLPATH

RUN yum install -y centos-release-scl-rh
RUN yum install -y devtoolset-11
RUN yum install -y bzip2-devel gdbm-devel krb5-devel libcom_err-devel \
                   libffi-devel ncurses-devel readline-devel sqlite-devel \
                   xz-devel zlib-devel

# RUN useradd $USER --home $HOMEROOT/$USER
# USER $USER
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
