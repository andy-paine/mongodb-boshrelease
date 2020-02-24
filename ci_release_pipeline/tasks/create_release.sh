#!/bin/bash

set -eux

version="$(cat mongodb_bosh_release_version/version"
cd mongodb_bosh_release_git

bosh create-release --force \
  --tarball "../release_tarball/mongodb-$version.tgz"
