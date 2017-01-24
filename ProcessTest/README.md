This directory contains scripts and documentation to run
ProcessTest application on Azure resources.

The tasks are defined in a simplified syntax in one of the
`*-list.json` files. Each task is an entry in the array
with the command line to execute the task.

Type: `python gen-jobs.py crosssections-list.json jobs.json`
to generate a shipyard jobs json file for cross-sections validation into 
`jobs.json` file.

For single interactions the list file is also by itself genreated because
the list of macros that can be used are queried running the ProcessTest
docker image.  
Edit the file `all_macros.sh` to setup where on host the G4 databases
are located.  
then run the script specifying the physics list: 
`./all_macros.sh FTFP_BERT` to generate the list file. 
This is needed only if the list of files changes.
 
