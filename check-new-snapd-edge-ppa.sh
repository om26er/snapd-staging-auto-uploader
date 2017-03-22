#!/bin/bash

set -eu

PACKAGE='snapd'
OUR_LP_ID='canonical-platform-qa'
OUR_PPA='snapd-edge'
UPSTREAM_LP_ID='snappy-dev'
UPSTREAM_PPA='edge'
DISTRO='xenial'
ARCH='amd64'

finish() {
    rm -rf "$tempdir"
}

get_package_version_from_ppa() {
    echo $(wget -q -O - http://ppa.launchpad.net/$1/$2/ubuntu/dists/$3/main/binary-$4/Packages.gz | zcat | grep-dctrl -PX $5 -s Version | awk '{print $NF}')
}

download_source_and_upload_to_ppa() {
    tempdir=$(mktemp -d)
    trap finish EXIT
    cd $tempdir
    dget -xu https://launchpad.net/~$UPSTREAM_LP_ID/+archive/ubuntu/$UPSTREAM_PPA/+files/${PACKAGE}_$version_in_upstream_ppa.dsc
    cd snapd-*/
    sed -i 's/.*\(DEB_BUILD_OPTIONS=\).*/DEB_BUILD_OPTIONS += nocheck testkeys/' debian/rules
    export DEBFULLNAME='Omer Akram'
    export DEBEMAIL='omer.akram@canonical.com'
    dch -ltestkeys "Build with testkeys."
    dch -r 'Release with test keys.' --distribution $DISTRO
    debuild -S -sd -k376A1FA7
    cd -
    dput ppa:$OUR_LP_ID/$OUR_PPA snapd_*testkey*_source.changes
}

version_in_our_ppa=$(get_package_version_from_ppa $OUR_LP_ID $OUR_PPA $DISTRO $ARCH $PACKAGE | awk '{split($0,a,"testkeys"); print a[1]}')
version_in_upstream_ppa=$(get_package_version_from_ppa $UPSTREAM_LP_ID $UPSTREAM_PPA $DISTRO $ARCH $PACKAGE)

echo "Version in our ppa ($OUR_PPA): $version_in_our_ppa"
echo "Version in upstream ppa ($UPSTREAM_PPA): $version_in_upstream_ppa"

is_new_version_available=$(echo $version_in_our_ppa $version_in_upstream_ppa | python3 -c "import sys; from datetime import datetime; input = [i for i in sys.stdin.read().strip().split()]; print(1 if datetime.strptime(input[1].split('+')[1].split('.')[0], '%Y%m%d%H%M') > datetime.strptime(input[0].split('+')[1].split('.')[0], '%Y%m%d%H%M') else 0)")

if [ "$is_new_version_available" -eq "0" ]; then
    echo "Update available."
    #download_source_and_upload_to_ppa
else
    echo "Our ppa is already upto date."
fi
