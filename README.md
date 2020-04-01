# <p style="text-align:center">Mongodb Bosh Release</p>

## Contents

  * [Purpose](#purpose)
  * [What should the Release do](#what-should-the-release-do)
  * [Development](#development)
    + [Building](#building)
    + [Templating](#templating)
    + [Cluster authentication](#cluster-authentication)
    + [Users](#users)
    + [Upgrading MongoDB](#upgrading-mongodb)
    + [CI Pipeline](#ci-pipeline)
  * [Installation](#installation)
    + [Clone the repository](#clone-the-repository)
    + [Example manifests](#example-manifests)
    + [Debugging](#debugging)
    + [Scaling](#scaling)
      + [Adding shards](#adding-shards)
  * [Acceptance tests](#acceptance-tests)
  * [Broker](#broker)
    + [Mongodb Broker](#mongodb-broker-broker-job)
    + [Mongodb Broker Smoke Tests](#mongodb-broker-smoke-tests-broker-smoke-tests-job)
  * [Configuring CF to use Mongodb service](#configuring-cf-to-use-mongodb-service)
    + [Available Plans](#available-plans)
    + [Broker registration](#broker-registration)
    + [Service provisioning](#service-provisioning)
    + [Service binding](#service-binding)
    + [Service unbinding](#service-unbinding)
    + [Service deprovisioning](#service-deprovisioning)

## Purpose

This project is a [Mongodb](https://www.mongodb.com) [Bosh](http://bosh.io) release.
The blobs are the provided ones from the mongodb community and are not compiled anymore. So the release can now only be deployed on an ubuntu stemcell.

This version excludes the rocksdb engine, which is not supported anymore.

## What should the Release do

* Configure a standalone or a set of standalone servers
* Configure a replica set
* Configure a sharded cluster including config server and mongos
* Complete requirements for mongodb servers ([production notes](https://docs.mongodb.org/manual/administration/production-notes/))
* Install mongodb component (shell / tools / mongod)

## Development

This release uses [BPM](https://github.com/cloudfoundry/bpm-release) for process management. This means there is no need for control scripts or any pidfile handling. The `monit` file instead tracks a pidfile created and managed by BPM and the control script is replaced by the `bpm.yml` config file. See the [docs on migrating to BPM](https://bosh.io/docs/bpm/transitioning/) for a more detailed description of what each file does.

### Building

To build the release, you will need to sync the blobs from S3. Ensure you have valid AWS credentials in your environment for the `smarsh-bosh-release-blobs` bucket then run `bosh sync-blobs`. After syncing the blobs you can run `bosh create-release --force` to build a new release.
> Note: This will build a dev release which should **not** be used in production. Final releases are continuously built from master and published to the `smarsh-bosh-releases` S3 bucket.

### Templating

Since most of the jobs in this release are running `mongod` or `mongos`, a lot of the configuration is similar too. To avoid repetition, there is a shared [templates](templates/) directory which is symlinked into each of the relevant jobs.
> Note: Some editors (e.g. VSCode) will make the symlink look like it is a true subdirectory so be careful when editing any templates that the changes are relevant to all jobs using it.

### Cluster authentication

Components of the cluster authenticate with each other using [x509 membership authentication](https://docs.mongodb.com/manual/tutorial/configure-x509-member-authentication/). A shared CA is given to each VM which then issues itself a certificate from that CA. This allows for scaling up the cluster without having to add new certificates for members as only the CA is needed. The certificate for the CA can be given to clients that need to trust the cluster.

### Users

This release is capable of creating users within the cluster. This approach is encouraged to allow for the users to be properly source controlled and repeatably deployed. The `mongod`, `mongos` and `shardsvr` jobs are all capable of creating users by setting `users` job property in the following format.
```yaml
users:
- name: root
  password: ((root_password))
  roles:
  - { role: root, db: admin }
- name: monitoring
  password: ((monitoring_password))
  roles:
  - { role: clusterMonitor, db: admin }
  - { role: read, db: local
```

### Upgrading MongoDB

To upgrade the version of MongoDB, a new blob will need to be added. Download the new `TGZ` package of MongoDB from the [MongoDB download center](https://www.mongodb.com/download-center/community). To add this blob, run `bosh add-blob <path_to_tarball.tgz> mongodb/mongodb-linux-x86_64-<new_version>.tar.gz`. The old blob should then be removed with `bosh remove-blob mongodb/mongodb-linux-x86_64-<old_version>.tar.gz`. To upload the new blob to the blobstore, ensure you have valid AWS credentials in your environment for the `smarsh-bosh-release-blobs` bucket then run `bosh upload-blobs`. Commit and push the changes to `blobs.yml` and check the pipeline successfully built the new release.

### CI Pipeline

This release is continuously built from master on the Smarsh prod Concourse. The pipeline lives in [ci/pipeline.yml](ci/pipeline.yml).

## Installation

### Clone the repository

```sh
git clone --recursive https://github.com/Smarsh/mongodb-boshrelease.git
```

### Example manifests

Two example manifests are provided for single replicaset or sharded deployment and can be found in the `manifests` directory. The manifest used for testing this release can be found in the [ci directory](ci/files/manifest.yml)

### Debugging

Logs for all mongo cluster jobs are available in the `/var/vcap/sys/log/<job>/` directory or via `bosh logs`. To investigate the cluster, shell scripts which are pre-authenticated against the cluster are provided with the relevant jobs (see below).
| Cluster type         | Run     |
| --------------- | ----------- |
| replicaset         | `/var/vcap/jobs/mongod/bin/mongo`    |
| sharded         | `/var/vcap/jobs/mongos/bin/mongo`    |

### Scaling

All datastore components of the cluster contain [pre-start scripts](https://bosh.io/docs/pre-start/) and [drain scripts](https://bosh.io/docs/drain/) that allow them to gracefully enter and leave the cluster. This should allow for zero-downtime scaling in and out of the cluster but this should be tested in a pre-production environment first. To expand the storage of a replicaset, increase the size of the disk allocated to the BOSH VMs.

#### Adding shards

To expand the storage of a sharded cluster, additional shards can be added. To add a new shard, a new instance group running `shardsvr` should be created and the BOSH links of the existing `shardsvr` instance grpups updated to use [explicit self links](https://bosh.io/docs/links/#self). An example [ops file](https://bosh.io/docs/cli-ops-files/) to add an additional, identical shard to the [sharded example manifest](manifests/manifest-shard.yml) can be found in [manifests/ops/add-additional-shard.yml](manifests/ops/add-additional-shard.yml).

## Acceptance tests

This release comes with an acceptance test errand for validating deployed clusters. See the [CI manfiest](ci/files/manifest.yml) for an example of how to configure this errand. You should include the following test suites for the relevant cluster types.
> Note: The acceptance tests for replicasets and sharding require a user with `root` privileges in each of the replicasets.

| Cluster type | Run |
| --------------- | ----------- |
| single instance | replicaset |
| replicaset | readwrite, replicaset |
| sharded (single shard) | readwrite, replicaset |
| sharded (multiple shards) | readwrite, replicaset, sharding |

## Broker
> Note: The broker has not been tested since this release was rewritten for Smarsh. Use at your own risk.

### Mongodb Broker (broker job)

The mongodb broker implements the 5 REST endpoints required by Cloud Foundry to write V2 services :
* Catalog management in order to register the broker to the platform
* Provisioning in order to create resource in the mongodb server
* Deprovisioning in order to release resource previously allocated
* Binding (credentials type) in order to provide application with a set of information required to use the allocated service
* Unbinding in order to delete credentials resources previously allocated

### Mongodb Broker Smoke Tests (broker-smoke-tests job)

The mongodb broker smoke test acts as an end user developer who wants to host its application in a cloud foundry.

For that, it relies on a sample mongodb application : https://github.com/JCL38-ORANGE/cf-mongodb-example-app

The following steps are performed by the smoke tests job :
* Authentication on Cloud Foundry by targeting org and space (cf auth and cf target)
* Deployment of the sample mongodb application (cf push)
* Provisioning of the service (cf create-service)
* Binding of the service (cf bind-service)
* Restaging of the sample mongodb application (cf restage)
* Table creation in the mongodb cluster (HTTP POST command to the sample mongodb application)
* Table deletion in the mongodb cluster (HTTP DELETE command to the sample mongodb application)

## Configuring CF to use Mongodb service

### Available Plans

For the moment, only 1 default plan available for shared Mongodb.

### Broker registration

The broker uses HTTP basic authentication to authenticate clients. The `cf create-service-broker` command expects the credentials for the cloud
controller to authenticate itself to the broker.

```bash
cf create-service-broker p-mongodb-broker <user> <password> <url>
cf enable-service-access mongodb
```

### Service provisioning

```bash
cf create-service mongodb default mongodb-instance
```

### Service binding

```bash
cf bind-service mongodb-example-app mongodb-instance
```
### Service unbinding

```bash
cf unbind-service mongodb-example-app mongodb-instance
```
### Service deprovisioning

```bash
cf delete-service mongodb-instance
```