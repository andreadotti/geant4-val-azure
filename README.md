Geant4 validation on Azure batch
================================

Introduction
------------
A wrapper around `batch-shipyard` specific for validation jobs fo Geant4
See: 
 
 1. [Validation Docker Image](https://github.com/andreadotti/docker-geant4-val)
 2. [Docker Repository](https://hub.docker.com/r/andreadotti/geant4-val/)

The main goal of this small bash application is to
allow for an easy generation of `jobs.json` configuraiton file for
batch-shipyard based on specific Geant4 needs.  
It provides interfaces to the most common batch-shipyard commands
auto-generating the configuration files.

Prerequisites
-------------

 1. [jq](https://stedolan.github.io/jq/) Ver > 1.3 (works with 1.5)
 2. [batch-shipyard](https://github.com/Azure/batch-shipyard) at least 
    version 2.5.1 is required

Usage
-----
Type `az-batch -h` for help. The general structure of the command is
`az-batch <command> [subcommand] [options] <summaryfile>`. 
For example to submit jobs according to a recipe (see later), you will:

 1. Edit the json configuration files
 2. Initialize a batch pool on Azure: 
    `az-batch init -r recipename summary.json`. You can skip this step if
    `add_pool` property is set to true in the summary json file.
 3. Submit jobs: `az-batch submit -r recipename summary.json`
 4. *Optional*: Monitor the status of jobs: 
    `az-batch status -r recipename summary.json`
 5. *Optional*: Retrieve stdout/stderr from a job:
    `az-batch getfile stdout.txt -t taskID -r reccipename summary.json`
    For all files skip the file name, for all tasks, skip the `-t` option
 6. Deallocate pool once finished: 
    `az-batch terminate -r recipename summary.json`

**Note**: You cannot add jobs to an existing pool unless all jobs use the 
same docker image (the image is pulled when pool is created). This means 
if you want to run two set of jobs that use different images you can create
a separate pool for each set of jobs or wait for the first set to end and
restart the pool.

Configuration
-------------
As for batch-shipyard configuration is provided via a set of json
configuration files. A top-level configuration file `summary.json`
specifies the shipyard specific files and general configuration.  
File content:
```
{
  "add_pool": false,
  "registry": null,
  "docker_image":"andreadotti/geant4-val:latest",
  "azure_output_container":null,
  "configurations": {
    "credentials": "credentials.json",
    "config": "config.json",
    "pool": "pool.json",
    "jobs": null 
  },  
  "recipes": {
    "crosssections": " ... "
  }
}
```

 * If `add_pool` is set to true, initialize pool automatically when
   submitting jobs. 
 * Specify in `registry` the server name for the registry (e.g. gitlab-registry.cern.ch)
   If images are on github no need to specify.  If a registry
   is specified, the `credentials.json` file must contain an entry in 
   `docker_registry` with the registry name as property for username and pwd
 * `docker_image` is the Geant4 validation docker image to use.
 * `azure_output_container` is the name of the Azure storage container
   blob where to store output data. It should already exist. If null, 
   container name is the recipe name being used (if no recipe is used
   a default name "outpucontainer" is used). The container is created
   on the storage account if not present.
 * `configurations` an object specifying the names of the batch-shipyard
   configuration files. They must all be present with the expcetion of
   `jobs`, this can be null, in such a case it will be auto generated
   following one of the provided recipes.
 * `recipes` is an object containing properties (the recipe names) and one
   or more bash commands that are used to generate a valid
   batch-shipyard jobs.json configuration file.

Note that the az-batch script may modify some of the batch-shipyard
configuration files based on the content of the summary.json file (e.g.
the docker image to be used).  
Recipes are strings of shell commands to generate jobs json file. 
The auto-generated file should be called `.gen-jobs.json` and should be
placed in the same directory where all other json files are located.

A tarball containing these generated files will be created in $PWD.

*TODO?*: move all configuration files inline in summary.json (script will
then split the files into the shipyard ones)

Batch-shipyard configuration files and additional informaiton
-------------------------------------------------------------

### Note on accounts being used
In the various json configuration files storage and batch accounts
are referenced via aliases. The Azure identifier (name) of the accounts
should be changed in the `credentials.json` file and **not** in the other
files (e.g. `config.json`).

### Credentials
Copy the `credentials-template.json` file and add the passwords from
azure accunts and docker registries.

### General configuraions and pools
`global.conf` and `pool.json` configure general parameters and the pool to be
used.

### Example for jobs configuration
The file `jobs-example.json` is a standalone example with a single task 
using the 
[andreadotti/geant4-val:latest](https://hub.docker.com/r/andreadotti/geant4-val/) 
docker image that should contain the `ProcessTest` application.

Under the directory `ProcessTest` real configuration files can be found.  
Since the corresponding jobs json configuration file is quite long and 
tedious to write, scripts to genrate them are provided. Refer to the 
instructions contained in that directory.

**Note:** for some functionalities, this script requires that tasks have 
an explicit id, thus is mandatory, differently from original shipyard.

Manual usage of batch-shipyard
------------------------------
Some notes for reference.

### Start tasks

 1. Add pool: `shipyard pool add --credentials credentials.json --config global.json --pool pool.json`
 2. Generate jobs file if needed: `cd ProcessTest && python gen-jobs-crosssections.py crosssections-list.json`
 3. Add jobs: `shipyard jobs add --credentials credentials.json --config global.json --pool pool.json --jobs ProcessTest/gen-jobs.json`

### Stop tasks
To remove tasks meta-data: `shipyard jobs del --credentials credentials.json --config global.json --pool pool.json --jobs jobs-example.json`
To remove pool: `shipyard pool del --credentials credentials.json --config global.json --pool pool.json --jobs jobs-example.json`

### Docker
A docker container is available. The `Dockerfile` is the one used to create the image on 
dockerhub: [andreadotti/geant4-azure-tools](https://hub.docker.com/r/andreadotti/geant4-azure-tools/).  
If something in the application changes these files must be re-generated.  
How to use. On the host setup the credentials file, then run:
```
docker run -t -i -v "$PWD:/myjobs:rw" andreadotti/geant4-azure-rools /bin/bash
$ cd /myjobs
$ az-batch init summary-docker.json
$ az-batch submit -r FTFP_BERT_Compton summary-docker.json
```
If you need to manipulate database files, add another `-v` option mounting the 
volume with the DBs in the image.  

