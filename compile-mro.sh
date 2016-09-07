#!/bin/bash
# Debian

R_VERSION="3.3.1"
CHECKPOINT_SNAPSHOT_DATE="2016-07-01"
NEW_CONNECTION_LIMIT="2048"
DEST_DIR="/usr/lib64/microsoft-r/${R_VERSION:0:3}"

apt-get update
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install \
    build-essential gfortran libreadline-dev libx11-dev libxt-dev zlib1g-dev libbz2-dev liblzma-dev \
    libpcre3-dev libcurl4-openssl-dev openjdk-7-jdk openjdk-7-jre

wget https://github.com/Microsoft/microsoft-r-open/archive/MRO-${R_VERSION}.tar.gz
tar -xvf MRO-${R_VERSION}.tar.gz

cd microsoft-r-open-MRO-${R_VERSION}/

patch -p0 -i patch/relocatable-r.patch
cd source
./tools/rsync-recommended
sed -i "s/#define NCONNECTIONS 128/#define NCONNECTIONS ${NEW_CONNECTION_LIMIT}/" src/main/connections.c
mkdir build
cd build

../configure LIBnn=lib64 --enable-R-shlib
make -j `nproc`
make prefix=${DEST_DIR} install
rm -r ${DEST_DIR}/bin

ln -s ${DEST_DIR}/lib64/R/bin/R /usr/bin/R
ln -s ${DEST_DIR}/lib64/R/bin/Rscript /usr/bin/Rscript

cd ../../additionalPackages
Rscript -e "install.packages(c('foreach', 'iterators', 'RUnit', 'checkpoint'), repos='http://mran.microsoft.com/snapshot/${CHECKPOINT_SNAPSHOT_DATE}')"
R CMD INSTALL -l ${DEST_DIR}/lib64/R/library/ doParallel RevoIOQ RevoMods RevoUtils

cp ../../../Rprofile.site /${DEST_DIR}/lib64/R/etc/Rprofile.site

R CMD javareconf # additional Java reconfiguration might be helpful

# Compress files:
#   tar -cvf mro-${R_VERSION}.tar.gz ${DEST_DIR}

# Extract files:
#   tar -xvf mro-${R_VERSION}.tar.gz -C /

# Uninstall R:
#   rm -r ${DEST_DIR}
#   rm /usr/bin/R
#   rm /usr/bin/Rscript
