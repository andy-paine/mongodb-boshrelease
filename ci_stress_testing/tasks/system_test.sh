#!/bin/bash

set -eux

export BOSH_NON_INTERACTIVE=true
export BOSH_DEPLOYMENT=mongodb

start-bosh \
  -o /usr/local/bosh-deployment/uaa.yml \
  -o /usr/local/bosh-deployment/credhub.yml
source /tmp/local-bosh/director/env

bosh upload-stemcell xenial_stemcell/*.tgz
bosh upload-release mongodb_release/*.tgz

bosh -d mongodb deploy this_repo/ci_stress_testing/files/manifest.yml

# Submit example-topology via a Bosh errand
bosh run-errand acceptance_tests
