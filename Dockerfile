FROM centos:centos6 AS builder

# install gcc 8
RUN yum -y install centos-release-scl && \
    yum -y install devtoolset-8 devtoolset-8-libatomic-devel
ENV CC=/opt/rh/devtoolset-8/root/usr/bin/gcc \
    CPP=/opt/rh/devtoolset-8/root/usr/bin/cpp \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/g++ \
    PATH=/opt/rh/devtoolset-8/root/usr/bin:$PATH \
    LD_LIBRARY_PATH=/opt/rh/devtoolset-8/root/usr/lib64:/opt/rh/devtoolset-8/root/usr/lib:/opt/rh/devtoolset-8/root/usr/lib64/dyninst:/opt/rh/devtoolset-8/root/usr/lib/dyninst:/opt/rh/devtoolset-8/root/usr/lib64:/opt/rh/devtoolset-8/root/usr/lib:$LD_LIBRARY_PATH

# install other tapcell dependencies
RUN yum install -y wget git pcre-devel tcl-devel tk-devel vim && \
    wget http://prdownloads.sourceforge.net/swig/swig-4.0.0.tar.gz && \
    tar -xf swig-4.0.0.tar.gz && \
    cd swig-4.0.0 && \
    ./configure && \
    make && \
    make install

COPY . /tapcell
WORKDIR /tapcell
RUN make release
RUN mkdir -p /build/bin/ && \
    cp /tapcell/bin/tapcell /build/bin/

FROM centos:centos6 AS runner
RUN yum update -y && yum install -y tcl-devel
COPY --from=builder /tapcell/bin/tapcell /build/tapcell

RUN useradd -ms /bin/bash openroad
USER openroad
WORKDIR /home/openroad