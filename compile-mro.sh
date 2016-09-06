#!/bin/bash

# Ubuntu 14.04

R_VERSION="3.1.1"
NEW_CONNECTION_LIMIT="2048"

sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install build-essential gfortran libreadline-dev libx11-dev libxt-dev zlib1g-dev libbz2-dev liblzma-dev libpcre3-dev libcurl4-openssl-dev openjdk-7-jdk openjdk-7-jre

wget https://github.com/Microsoft/microsoft-r-open/archive/MRO-${R_VERSION}.tar.gz
tar -xvf microsoft-r-open-MRO-${R_VERSION}.tar.gz

cd microsoft-r-open-MRO-${R_VERSION}/

patch -p0 -i patch/relocatable-r.patch
cd source
./tools/rsync-recommended
sed -i "s/#define NCONNECTIONS 128/#define NCONNECTIONS ${NEW_CONNECTION_LIMIT}/" src/main/connections.c
mkdir build
cd build

../configure --enable-R-shlib
make -j `nproc`
sudo make prefix=/opt/mro install

cp ../../../Rprofile.site /opt/mro/lib/R/etc/Rprofile.site

cd ../../additionalPackages

sudo /opt/mro/lib/R/bin/Rscript -e "install.packages(c('foreach', 'iterators', 'RUnit', 'checkpoint'))"
sudo /opt/mro/lib/R/bin/R CMD INSTALL -l /opt/mro/lib/R/library/ doParallel RevoIOQ RevoMods RevoUtils

# R and Rscript paths:
#    /opt/mro/lib/R/bin/R
#    /opt/mro/lib/R/bin/Rscript

# Compress files:
#   tar -cvf mro-3.1.1.tar.gz /opt/mro

# Extract files:
#   sudo tar -xvf mro-3.1.1.tar.gz -C /

# Create symbolic links:
#   sudo ln -s /opt/mro/lib/R/bin/R /usr/bin/R
#   sudo ln -s /opt/mro/lib/R/bin/Rscript /usr/bin/Rscript

# Sometimes reconfiguring Java will be helpful:
#   sudo R CMD javareconf

# Uninstall R:
#   sudo rm -r /opt/mro
