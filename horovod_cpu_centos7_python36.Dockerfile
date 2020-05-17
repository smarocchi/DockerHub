FROM centos:centos7

# Python

ENV TENSORFLOW_VERSION=2.1.0
ENV PYTORCH_VERSION=1.4.0
ENV TORCHVISION_VERSION=0.5.0
ENV MXNET_VERSION=1.6.0

# Python 3.6 is supported by Ubuntu Bionic out of the box
ARG python=3.6
ENV PYTHON_VERSION=${python}

# Set default shell to /bin/bash
CMD ["/bin/bash", "-cu"]

RUN yum -y groupinstall "Development tools" && \
    yum install -y epel-release \
                   python36 \
                   python3-pip \
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
                   openssl && \
                                  yum  -y install libibverbs-dev \
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
                                                  subversion && \
    svn checkout https://github.com/horovod/horovod/trunk/examples && \
    rm -rf /examples/.svn && mkdir -p /var/run/sshd                                                                                                    

# upgrade pip with pip
RUN pip3 install --upgrade pip 

# Allow OpenSSH to talk to containers without asking for confirmation
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# Install TensorFlow, Keras, PyTorch and MXNet
RUN pip3 install future typing
RUN pip3 install numpy \
        tensorflow==${TENSORFLOW_VERSION} \
        keras \
        h5py
RUN pip3 install torch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERSION}
RUN pip3 install mxnet==${MXNET_VERSION}

# Install Open MPI
RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.0.tar.gz && \
    tar zxf openmpi-4.0.0.tar.gz && \
    cd openmpi-4.0.0 && \
    ./configure --enable-orterun-prefix-by-default --disable-getpwuid && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

# Install Horovod
RUN HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITH_MXNET=1 \
    pip3 install --no-cache-dir horovod

WORKDIR "/examples"
