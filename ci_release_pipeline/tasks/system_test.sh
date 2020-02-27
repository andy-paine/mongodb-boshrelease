#!/bin/bash

set -eux

export BOSH_NON_INTERACTIVE=true
export BOSH_DEPLOYMENT=mongodb

start-bosh \
  -o /usr/local/bosh-deployment/uaa.yml \
  -o /usr/local/bosh-deployment/credhub.yml
source /tmp/local-bosh/director/env

# Upload releases and stemcell
bosh upload-stemcell xenial_stemcell/*.tgz
bosh upload-release mongodb_bosh_candidate_release_s3/*.tgz

# Deploy and run acceptance test errand
bosh deploy mongodb_bosh_release_git/ci_release_pipeline/files/manifest.yml
bosh run-errand acceptance_tests --keep-alive

# Recreate all vms in the deployment and run acceptance test errand
bosh recreate
bosh run-errand acceptance_tests --keep-alive

# Restart processes on instances and run acceptance test errand
bosh restart
bosh run-errand acceptance_tests --keep-alive

bosh upload-stemcell old_xenial_stemcell/*.tgz
bosh deploy mongodb_bosh_release_git/ci_release_pipeline/files/manifest.yml \
  -o mongodb_bosh_release_git/ci_release_pipeline/files/use_old_stemcell.yml
bosh run-errand acceptance_tests --keep-alive
