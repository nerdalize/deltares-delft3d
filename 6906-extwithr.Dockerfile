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
ADD 6906-extwithr /delft3d
RUN cd /delft3d/src \
  && sed --in-place 's/~/\/root/' build_ubuntu1604.sh \
  && find /delft3d/src -type f -iname "*.sh" -exec chmod +x {} \; \
  && ./build_ubuntu1604.sh -gnu -64bit

RUN cp /root/Downloads/libraries/mpich-3.2/bin/* /delft3d/bin/lnx64/flow2d3d/bin/
RUN cp -R /root/Downloads/libraries/mpich-3.2/lib/* /delft3d/bin/lnx64/flow2d3d/bin/
RUN mkdir -p /mpi/bin && cp -R $MPICH2_3_2_DIR/bin/* /mpi/bin

#R
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		locales \
	&& rm -rf /var/lib/apt/lists/*

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list \
    && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
    && gpg -a --export E084DAB9 | apt-key add -

ENV R_BASE_VERSION 3.4.1
RUN apt-get update && apt-get install -y \
		littler \
    r-cran-littler \
		r-base=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
		r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libgdal-dev \
    libproj-dev

RUN Rscript -e "install.packages('stringr')" \
  && Rscript -e "install.packages('sqldf')" \
  && Rscript -e "install.packages('ncdf4')" \
  && Rscript -e "install.packages('raster')" \
  && Rscript -e "install.packages('XML')" \
  && Rscript -e "install.packages('rgdal')" \
  && Rscript -e "install.packages('rgeos')"

WORKDIR /delft3d/examples/01_standard
