#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Wrong number of arguments!"
    echo "Must run as $0 <download_url> <distro> <launchpad_id> <ppa_name>"
    exit 1
fi

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
export DEBFULLNAME='platform-qa-bot'
export DEBEMAIL='platform-qa-bot@canonical.com'
dch -ltestkeys "Build with testkeys."
dch -r 'Release with testkeys.' --distribution $DISTRO
debuild -S -sd -k46C33555
cd -
#dput ppa:$LP_ID/$PPA snapd_*testkey*_source.changes
