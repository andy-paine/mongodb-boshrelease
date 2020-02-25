#!/bin/bash
set -eux

version="$(cat mongodb_bosh_release_version/version)"
cd mongodb_bosh_release_git/

echo "creating final release"
bosh finalize-release ../mongodb_bosh_candidate_release_s3/mongodb-*.tgz \
  --version "$version" \
  --tarball "../release_tarball/mongodb-$version.tgz"
