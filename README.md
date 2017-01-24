Scripts and configuration files for running Geant4 validation on Azure batch
resources using batch-shipyard.

Install batch-shipyard and use the provided json configuration files:

#### Credentials
Copy the `credentials-template.json` file and add the credentials from
azure accunts and docker registries.

#### General configuraions and pools
`global.conf` and `pool.json` configure general aspecs and the pool to be
used.

### Jobs configuration
The file `jobs-example.json` is a standalone example with a single task using the 
`andreadotti/geant4-val:latest` docker image that should contain the
`ProcessTest` application.

Under the directory `ProcessTest` real configuration files can be found.  
Since the corresponding jobs json configuration file is quite long and 
tedious to write, scripts to genrate them are provided. Refer to the 
instructions contained in that directory.

## Start tasks
 1. Add pool: `shipyard pool add --credentials credentials.json --config global.json --pool pool.json`
 2. Generate jobs file if needed: `cd ProcessTest && python gen-jobs-crosssections.py crosssections-list.json`
 3. Add jobs: `shipyard jobs add --credentials credentials.json --config global.json --pool pool.json --jobs ProcessTest/gen-jobs.json`

## Stop tasks
To remove tasks meta-data: `shipyard jobs del --credentials credentials.json --config global.json --pool pool.json --jobs jobs-example.json`
To remove pool: `shipyard pool del --credentials credentials.json --config global.json --pool pool.json --jobs jobs-example.json`
