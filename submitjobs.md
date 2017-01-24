## Install shipyard
Needs to use shipyard. Manual installation as at:
(Documentation)[https://github.com/Azure/batch-shipyard/blob/master/docs/01-batch-shipyard-installation.md]

Probably for production is much better to use docker as shown there.

## Configuration files
For each application I want to run I create a sub-directory here with 
the shipyard configuration files.  
The `miscellaneus` storage is used internally by shipyard to store
metadata and other stuff.

### Credentials
`credentials*.json`
This is probably a single file with all credentials. In particular I need to 
put there all keys for storage, file shares for DBs and blob's containers.
The `credentials-template.json` should be edited to contain the passwords and 
keys.
**DO NOT PUT THE EDITED FILES WITH REAL PASSWORDS AND KEYS ON GITHUB**

### Global
`global.json`
(Documentation)[https://github.com/Azure/batch-shipyard/blob/master/docs/10-batch-shipyard-configuration.md#global]

#### Volumes
For `g4databases` volumes, the G4 imanges expect data under `/usr/local/geant4/data`,
from Azure file storage with account `g4databases` under share `g4db`.
For file/dir permissions, I try to set: 0744 for both since I want to give readonly permissions
but the `azurefile` driver seems not to support the explicit mount option:
[https://github.com/Azure/azurefile-dockervolumedriver].

### Pool
**Question**: Limitation of 20 cores to be understood...

This conf file will probably need to go in the sub-project dir since
each one could have different number of nodes, unless they are many. 
So a general one in top directory and in case in sub-dirs fi we need to
overwrite defaults.

### Jobs
Ok, use simply the template and for simplicity specify as output
anything that is in the `/output` directory. Since I'm uploading to the
same *Azure Storage Blob Container*, I rely on the naming of the output
not to overwrite.
**Question**: is probably a good idea to have different containers for
each validation campaign all in the same storage account

## Usage
 1. Create batch pool on azure (once), create container on storage g4data
 1. Add Pool: `shipyard pool add --credentials credentials.json --config global.json --pool pool.json`

