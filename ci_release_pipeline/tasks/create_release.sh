#!/bin/bash

set -eux

version="$(cat mongodb_bosh_release_version/version)"
cd mongodb_bosh_release_git

# Download and add blob
wget -O /tmp/mongodb-linux-x86_64-ubuntu1604-3.6.6.tgz http://downloads.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.6.6.tgz
bosh add-blob /tmp/mongodb-linux-x86_64-ubuntu1604-3.6.6.tgz mongodb/mongodb-linux-x86_64-3.6.6.tar.gz

# Create candidate release
bosh create-release --force \
  --version "$version" \
  --tarball "../release_tarball/mongodb-$version.tgz"
