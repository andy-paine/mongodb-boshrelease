#!/bin/bash
set -eux

version="$(cat mongodb_bosh_release_version/version)"
cd mongodb_bosh_release_git/
RELEASE_YML=$PWD/releases/mongodb-services/mongodb-services-${version}.yml

echo "creating final release"
bosh finalize-release ../mongodb_bosh_candidate_release_s3/mongodb-*.tgz \
  --version "$version" \

bosh create-release "${RELEASE_YML}" \
  --tarball "../release_tarball/mongodb-$version.tgz"