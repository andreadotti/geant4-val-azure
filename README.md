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

 1. [jq](https://stedolan.github.io/jq/)
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

Configuration
-------------
As for batch-shipyard configuration is provided via a set of json
configuration files. A top-level configuration file `summary.json`
specifies the shipyard specific files and general configuration.  
File content:
```
{
  "add_pool": false,
  "docker_image":"andreadotti/geant4-val:latest",
  "azure_output_container":"processtest-10-3-0-9-8",
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
 * `docker_image` is the Geant4 validation docker image to use.
 * `azure_output_container` is the name of the Azure storage container
   blob where to store output data. It should already exist.
 * `configurations` an object specifying the names of the batch-shipyard
   configuration files. They must all be present with the expcetion of
   `jobs`, this can be null, in such a case it will be auto generated
   following one of the provided recipes.
 * `recipes` is an object containing properties (the recipe names) and one
   or more bash commands that are used to **generate** a valid
   batch-shipyard jobs.json configuration file.

Note that the az-batch script may modify some of the batch-shipyard
configuration files based on the content of the summary.json file (e.g.
the docker image to be used).  
Recipes is a string of shell commands to generate jobs json file. 
The auto-generated file should be called `.gen-jobs.json` and should be
placed in the same directory where all other json files are located.

The high-level script will modify/generate json files used by shipyard. 
A tarball containing these generated files will be created in $PWD.

*TODO?*: move all configuration files inline in summary.json (script will
then split the files into the shipyard ones)

Batch-shipyard configuration files and additional informaiton
-------------------------------------------------------------

### Credentials
Copy the `credentials-template.json` file and add the credentials from
azure accunts and docker registries.

### General configuraions and pools
`global.conf` and `pool.json` configure general aspecs and the pool to be
used.

### Example for jobs configuration
The file `jobs-example.json` is a standalone example with a single task 
using the 
`andreadotti/geant4-val:latest` docker image that should contain the
`ProcessTest` application.

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

