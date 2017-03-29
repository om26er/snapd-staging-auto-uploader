#!/bin/bash

set -eu

ARCHIVES='xenial-proposed'
PACKAGE='snapd'
OUR_LP_ID='canonical-platform-qa'
OUR_PPA='snapd-candidate'
DISTRO='xenial'
ARCH='amd64'

get_package_version_from_ppa() {
    echo $(wget -q -O - http://ppa.launchpad.net/$1/$2/ubuntu/dists/$3/main/binary-$4/Packages.gz | zcat | grep-dctrl -PX $5 -s Version | awk '{print $NF}')
}

version_in_proposed=$(rmadison snapd -s $ARCHIVES | awk '{split($0,a,"|"); print a[2]}' | sed -e 's/ //g')
version_in_our_ppa=$(get_package_version_from_ppa $OUR_LP_ID $OUR_PPA $DISTRO $ARCH $PACKAGE | awk '{split($0,a,"testkeys"); print a[1]}')

echo "Version in our ppa ($OUR_PPA): $version_in_our_ppa"
echo "Version in archives ($ARCHIVES): $version_in_proposed"

is_new_version_available=$(echo $version_in_proposed $version_in_our_ppa | python3 -c "import sys; from distutils.version import StrictVersion; input = [i for i in sys.stdin.read().strip().split()]; print(1 if StrictVersion(input[0]) > StrictVersion(input[1]) else 0)")

if [ "$is_new_version_available" -eq "0" ]; then
    echo "Update available."
    ./upload-to-ppa.sh https://launchpad.net/ubuntu/+archive/primary/+files/${PACKAGE}_$version_in_proposed.dsc $DISTRO $OUR_LP_ID $OUR_PPA
else
    echo "Our ppa is already upto date."
fi
