#!/bin/bash

set -eu

JUNEST_BUILDER=/home/builder/junest-builder

# Cleanup and initialization
[ -d ${JUNEST_BUILDER} ] && rm -rf ${JUNEST_BUILDER}
mkdir -p ${JUNEST_BUILDER}/tmp
mkdir -p ${JUNEST_BUILDER}/junest
sudo rm -rf ${JUNEST_BUILDER}/*

build_aur_package() {
    local package=$1
}

# ArchLinux System initialization
sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm git base-devel arch-install-scripts haveged
sudo systemctl start haveged
mkdir -p ${JUNEST_BUILDER}/tmp/package-query
cd ${JUNEST_BUILDER}/tmp/package-query
curl -L -J -O -k "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=package-query"
makepkg --noconfirm -sfc
sudo pacman --noconfirm -U package-query*.pkg.tar.xz
mkdir -p ${JUNEST_BUILDER}/tmp/yaourt
cd ${JUNEST_BUILDER}/tmp/yaourt
curl -L -J -O -k "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yaourt"
makepkg --noconfirm -sfc
sudo pacman --noconfirm -U yaourt*.pkg.tar.xz
yaourt -S --noconfirm python-guzzle-sphinx-theme
yaourt -S --noconfirm python-bcdoc
yaourt -S --noconfirm python-botocore
yaourt -S --noconfirm aws-cli

# Building JuNest image
mkdir -p ${JUNEST_BUILDER}/junest
cd ${JUNEST_BUILDER}
git clone https://github.com/cross-dev/junest ${JUNEST_BUILDER}/junest
JUNEST_TEMPDIR=${JUNEST_BUILDER}/tmp ${JUNEST_BUILDER}/junest/bin/junest -b kconfig-frontends make grep fakeroot file

for img in $(ls junest-*.tar.gz);
do
    aws s3 cp ${img} s3://crossdev/junest/ --acl public-read
done

rm -rf ${JUNEST_BUILDER}
