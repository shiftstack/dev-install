#!/bin/bash -x

version=$1
latest_nightly=$(curl -s https://openshift-release-artifacts.apps.ci.l2s4.p1.openshiftapps.com/ | awk "match(\$0, /($version.0-0.nightly-[-0-9]+)/, a) {print a[1]}" | tail -1)
wget "https://openshift-release-artifacts.apps.ci.l2s4.p1.openshiftapps.com/$latest_nightly/openshift-install-linux-${latest_nightly}.tar.gz"
mkdir $latest_nightly
tar -C $latest_nightly -xvzf openshift-install-linux-${latest_nightly}.tar.gz openshift-install
rm -rf openshift-install-linux-${latest_nightly}.tar.gz

