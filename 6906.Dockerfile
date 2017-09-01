FROM ubuntu:16.04
RUN apt-get update && apt-get install -y \
  autoconf \
  libtool \
  flex \
  g++ \
  gfortran \
  libstdc++6 \
  byacc \
  libexpat1-dev \
  uuid-dev \
  ruby \
  build-essential \
  wget \
  pkg-config \
  gedit

#zlib
ENV v=1.2.8
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/zlib-${v}.tar.gz \
    && tar -xf zlib-${v}.tar.gz \
    && cd zlib-${v} \
    && ./configure --prefix=/usr/local \
    && make install

#hdf5
ENV v=1.8.13
ENV HDF5_DIR="/root/Downloads/libraries/hdf5-${v}"
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/hdf5-${v}.tar.gz \
    && tar -xf hdf5-${v}.tar.gz \
    && cd hdf5-${v} \
    && ./configure --enable-shared --enable-hl --prefix=$HDF5_DIR \
    && make -j 2 \
    && make install

#netcdf
ENV v=4.4.1
ENV NETCDF4_DIR="/root/Downloads/libraries/netcdf_4.4"
RUN wget http://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-${v}.tar.gz \
    && tar -xf netcdf-${v}.tar.gz && cd netcdf-${v} \
    && CPPFLAGS=-I$HDF5_DIR/include LDFLAGS=-L$HDF5_DIR/lib ./configure --enable-netcdf-4 --enable-shared --enable-dap --prefix=$NETCDF4_DIR \
    && make \
    && make install

ENV PATH=$PATH:$NETCDF4_DIR/bin
ENV LD_LIBRARY_PATH=$NETCDF4_DIR/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=$NETCDF4_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

#netcdf fortran
ENV v=4.4.4
RUN wget http://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-${v}.tar.gz \
    && tar -xf netcdf-fortran-${v}.tar.gz \
    && cd netcdf-fortran-${v} \
    && CPPFLAGS=-I$NETCDF4_DIR/include LDFLAGS=-L$NETCDF4_DIR/lib LD_LIBRARY_PATH=$NETCDF4_DIR/lib:$LD_LIBRARY_PATH ./configure --prefix=$NETCDF4_DIR \
    && make \
    && make install

#mpi
ENV v=3.2
ENV MPICH2_3_2_DIR="/root/Downloads/libraries/mpich-3.2"
RUN wget http://www.mpich.org/static/downloads/${v}/mpich-${v}.tar.gz \
    && tar -xzf mpich-${v}.tar.gz \
    && cd mpich-${v} \
    && ./configure --prefix=$MPICH2_3_2_DIR \
    && make \
    && make install

ENV PATH=$PATH:$MPICH2_3_2_DIR/bin
ENV LD_LIBRARY_PATH=$MPICH2_3_2_DIR/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=$MPICH2_3_2_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

#delft3d
# NOTE: we need to replace the '~' with the actual path as it causes
# errors in the delft3d build script
RUN df -h
ADD 6906 /delft3d
RUN cd /delft3d/src \
  && sed --in-place 's/~/\/root/' build_ubuntu1604.sh \
  && ./build_ubuntu1604.sh -gnu -64bit

RUN cp /root/Downloads/libraries/mpich-3.2/bin/* /delft3d/bin/lnx64/flow2d3d/bin/
RUN cp -R /root/Downloads/libraries/mpich-3.2/lib/* /delft3d/bin/lnx64/flow2d3d/bin/

WORKDIR /delft3d/examples/01_standard
