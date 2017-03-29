#!/bin/bash

set -eu

PACKAGE='snapd'
OUR_LP_ID='canonical-platform-qa'
OUR_PPA='snapd-edge'
UPSTREAM_LP_ID='snappy-dev'
UPSTREAM_PPA='edge'
DISTRO='xenial'
ARCH='amd64'

get_package_version_from_ppa() {
    echo $(wget -q -O - http://ppa.launchpad.net/$1/$2/ubuntu/dists/$3/main/binary-$4/Packages.gz | zcat | grep-dctrl -PX $5 -s Version | awk '{print $NF}')
}

version_in_our_ppa=$(get_package_version_from_ppa $OUR_LP_ID $OUR_PPA $DISTRO $ARCH $PACKAGE | awk '{split($0,a,"testkeys"); print a[1]}')
version_in_upstream_ppa=$(get_package_version_from_ppa $UPSTREAM_LP_ID $UPSTREAM_PPA $DISTRO $ARCH $PACKAGE)

echo "Version in our ppa ($OUR_PPA): $version_in_our_ppa"
echo "Version in upstream ppa ($UPSTREAM_PPA): $version_in_upstream_ppa"

is_new_version_available=$(echo $version_in_our_ppa $version_in_upstream_ppa | python3 -c "import sys; from datetime import datetime; input = [i for i in sys.stdin.read().strip().split()]; print(1 if datetime.strptime(input[1].split('+')[1].split('.')[0], '%Y%m%d%H%M') > datetime.strptime(input[0].split('+')[1].split('.')[0], '%Y%m%d%H%M') else 0)")

if [ "$is_new_version_available" -eq "1" ]; then
    echo "Update available."
    ./upload-to-ppa.sh https://launchpad.net/~$UPSTREAM_LP_ID/+archive/ubuntu/$UPSTREAM_PPA/+files/${PACKAGE}_$version_in_upstream_ppa.dsc $DISTRO $OUR_LP_ID $OUR_PPA
else
    echo "Our ppa is already upto date."
fi
