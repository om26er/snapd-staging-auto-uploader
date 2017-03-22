#!/bin/bash

DOWNLOAD_URL=$1
DISTRO=$2
LP_ID=$3
PPA=$4

finish() {
    rm -rf "$tempdir"
}

tempdir=$(mktemp -d)
trap finish EXIT

cd $tempdir
dget -xu $DOWNLOAD_URL
cd snapd-*/
sed -i 's/.*\(DEB_BUILD_OPTIONS=\).*/DEB_BUILD_OPTIONS += nocheck testkeys/' debian/rules
export DEBFULLNAME='Omer Akram'
export DEBEMAIL='omer.akram@canonical.com'
dch -ltestkeys "Build with testkeys."
dch -r 'Release with test keys.' --distribution $DISTRO
debuild -S -sd -k376A1FA7
cd -
#dput ppa:$LP_ID/$PPA snapd_*testkey*_source.changes
