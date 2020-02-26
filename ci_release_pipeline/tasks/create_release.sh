#!/bin/bash

set -eux

version="$(cat mongodb_bosh_release_version/version)"
cd mongodb_bosh_release_git

# Create candidate release
bosh create-release --force \
  --version "$version" \
  --tarball "../release_tarball/mongodb-$version.tgz"
