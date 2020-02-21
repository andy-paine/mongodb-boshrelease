#!/bin/bash

set -eux

export BOSH_NON_INTERACTIVE=true
export BOSH_DEPLOYMENT=mongodb

start-bosh \
  -o /usr/local/bosh-deployment/uaa.yml \
  -o /usr/local/bosh-deployment/credhub.yml
source /tmp/local-bosh/director/env

bosh upload-stemcell xenial_stemcell/*.tgz
bosh upload-release mongodb/mongodb*.tgz

bosh -d mongodb deploy mongodb_release/ci_stress_testing/files/manifest.yml

bosh deploy mongodb_release/ci_stress_testing/files/manifest.yml \
  --vars-store=/tmp/mongodb_vars.yml \

# Submit example-topology via a Bosh errand
bosh run-errand acceptance-tests
