FROM centos:centos7.8.2003
#FROM centos:centos7.7.1908
#FROM centos:centos7.6.1810
#FROM centos:centos7.5.1804
#FROM centos:centos7.4.1708
#FROM centos:centos7.3.1611

# 7.3 is the available version in marconi a3  
# 7.4 is the version used to compile the openmpi working version

# Python
ENV TENSORFLOW_VERSION=2.1.0
ENV PYTORCH_VERSION=1.4.0
ENV TORCHVISION_VERSION=0.5.0
ENV MXNET_VERSION=1.6.0
ENV HOROVOD_VERSION=0.18.2

# Python 3.6 is supported by Ubuntu Bionic out of the box
ARG python=3.6
ENV PYTHON_VERSION=${python}

# Set default shell to /bin/bash
CMD ["/bin/bash", "-c"]

RUN yum -y groupinstall "Development tools" && \
    yum -y install epel-release \
                   python36 \
                   python3-pip \
                   python3-devel \
                   bzip2 \ 
                   gzip \
                   tar \
                   zip \
                   unzip \
                   xz \
                   curl \
                   wget \
                   vim \
                   patch \
                   make \
                   cmake \
                   file \
                   git \
                   which \
                   gcc-c++ \
                   perl-Data-Dumper \
                   perl-Thread-Queue \
                   boost-devel \
                   openssl

RUN  yum  -y install libibverbs-dev \
                     libibverbs-devel \
                                                  rdma-core-devel \
                                                  openssl-devel \
                                                  libssl-dev \
                                                  libopenssl-devel \
                                                  binutils \
                                                  dapl \
                                                  dapl-utils \
                                                  ibacm \
                                                  infiniband-diags \
                                                  libibverbs \ 
                                                  libibverbs-utils \
                                                  libmlx4 \
                                                  librdmacm \
                                                  librdmacm-utils \
                                                  mstflint \
                                                  opensm-libs \
                                                  perftest \
                                                  qperf \
                                                  rdma \
                                                  libjpeg-turbo-devel \
                                                  libpng-devel \
                                                  openssh-clients \ 
                                                  openssh-server \
                                                  subversion \ 
                                                  libffi \
                                                  libffi-devel \
                                                  devtoolset-7-gcc \
                                                  devtoolset-7-gcc-c++ \
                                                  scl-utils

RUN yum -y install centos-release-scl

RUN yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++ 


# LOAD GNU 7.3.1

# General environment variables
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin${PATH:+:${PATH}}
ENV MANPATH=/opt/rh/devtoolset-7/root/usr/share/man:${MANPATH}
ENV INFOPATH=/opt/rh/devtoolset-7/root/usr/share/info${INFOPATH:+:${INFOPATH}}
ENV PCP_DIR=/opt/rh/devtoolset-7/root
# Some perl Ext::MakeMaker versions install things under /usr/lib/perl5
# even though the system otherwise would go to /usr/lib64/perl5.
ENV PERL5LIB=/opt/rh/devtoolset-7/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-7/root/usr/lib/perl5:/opt/rh/devtoolset-7/root//usr/share/perl5/vendor_perl${PERL5LIB:+:${PERL5LIB}}
# bz847911 workaround:
# we need to evaluate rpm's installed run-time % { _libdir }, not rpmbuild time
# or else /etc/ld.so.conf.d files?
#RUN rpmlibdir=$(rpm --eval "%{_libdir}")
# bz1017604: On 64-bit hosts, we should include also the 32-bit library path.

#RUN if [ "$rpmlibdir" != "${rpmlibdir/lib64/}" ]; then rpmlibdir32=":/opt/rh/devtoolset-7/root${rpmlibdir/lib64/lib}" fi

ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root$rpmlibdir$rpmlibdir32${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root$rpmlibdir$rpmlibdir32:/opt/rh/devtoolset-7/root$rpmlibdir/dyninst$rpmlibdir32/dyninst${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# duplicate python site.py logic for sitepackages
ENV pythonvers=3.6
ENV PYTHONPATH=/opt/rh/devtoolset-7/root/usr/lib64/python$pythonvers/site-packages:/opt/rh/devtoolset-7/root/usr/lib/python$pythonvers/site-packages${PYTHONPATH:+:${PYTHONPATH}}


RUN gcc --version


RUN mkdir -p /var/run/sshd && \
   pip3 install --upgrade pip 

# Allow OpenSSH to talk to containers without asking for confirmation
#RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
#    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
#    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

#RUN yum -y install pmix-devel

#RUN yum -y install slurm-libpmi

RUN yum -y install libpsm2 libpsm2-devel

# Install Open MPI
RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.0.tar.gz && \
    tar zxf openmpi-4.0.0.tar.gz && \
    cd openmpi-4.0.0 && \
    ./configure --prefix=/opt/openmpi --disable-getpwuid --with-psm2=yes --with-memory-manager=none  --enable-static=yes --with-pmix --enable-shared --with-verbs --enable-mpirun-prefix-by-default --disable-dlopen --enable-wrapper-rpath=no --enable-wrapper-runpath=no  && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi


ENV PATH=/opt/openmpi/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/openmpi/lib:${LD_LIBRARY_PATH}


# I avoid to use --with-mpi because I lack the correct libraries

ENV TENSORFLOW_VERSION=1.14.0

# Install TensorFlow, Keras, PyTorch and MXNet
RUN pip3 install future typing
RUN pip3 install numpy \
        tensorflow==${TENSORFLOW_VERSION} \
        keras \
        h5py
RUN pip3 install torch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERSION}
RUN pip3 install mxnet==${MXNET_VERSION}

ENV HOROVOD_VERSION=0.18.1

# Install Horovod
RUN HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITH_MXNET=1 \
    pip3 install --no-cache-dir horovod==${HOROVOD_VERSION}

# --no-cache-dir

# download and install horovod
#RUN cd /tmp && \
#    git clone https://github.com/horovod/horovod.git --recursive && \
#    cd horovod 

#RUN cd /tmp/horovod && \
#    git checkout tags/v0.18.2 && \
#    python3 setup.py sdist && \
#    HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITH_MXNET=1 pip3 install --no-cache-dir dist/horovod-*.tar.gz

WORKDIR "/examples"
