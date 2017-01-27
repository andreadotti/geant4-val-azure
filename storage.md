
### Start docker image with azure-cli 2.0
`docker run -it azuresdk/azure-cli-python:latest bash`  
Realistic run:
`docker run -ti -v "/geant4-sw/data:/g4data:ro" -v "$PWD:/workdir" -w /workdir azuresdk/azure-cli-python:latest bash`

### HElp
`az login -h` add all keywords plus -h: `az storage file list -h`

### Login
`az login` go to website and put code, then login (direct 
login with pwd on cli does not work for slac account).  
I am not sure when this must be done, restarting docker, does not require
this once the key is correctly set-up.

### Connect to storage account:
```
export AZURE_STORAGE_ACCOUNT=g4databases
export AZURE_STORAGE_ACCESS_KEY=<key-from-portal>
```
Get the key from the portal: select the storage account -> Access Keys -> Copy one of the two.
The account name is **g4databases**, on this we have a **file share** 
called **g4db**. This is a directory structure with files. I put G4dbs inside 
this share. We have this two because the type of storage is at the level of the
account, while the file share is the type (vs e.g. a blob). The storage
account defines the redundancy for example.

#### List share content:
```
az storage file list --share-name g4db
#Content of test directory
az storage file list --share-name g4db --path ./Test1
```
-s => --share-name ; -p => --path 

#### Download share content:
`az storage file download -s g4db -p ./Test1/200MeV.txt [--dest]`
NB: To understand format and possible windows encoding for end-of-line

### Add a DB:
`az storage directory create -s g4db --name <DBname>`
-n => --name
Single file upload:
`az storage file upload -s g4db --source <DBname>`

Batch upload, big issue: cannot do recoursive tree!
`az storage file upload-batch --destination <url>`
destination url is for example: https://g4databases.file.core.windows.net/g4db/PhotonEvaporation4.3

So at the end I am creating tarballs from my desktop, uploading it to 
the storage, and from a Azure VM, unpack-it in a mount:
```
sudo mount -t cifs //g4databases.file.core.windows.net/g4db \
	/mnt/g4db -o vers=3.0,username=g4databases,\
	password=$AZURE_STORAGE_KEY,dir_mode=0777,file_mode=0777
```

**TODO**: Study/check project (bobxfer)[https://github.com/Azure/blobxfer]
it seems what I need since it supports recursive copyes.
IT works:
```
source ~/Work/Azure/storage-g4databases.sh #For credentials
blobxfer --storageaccountkey $AZURE_STORAGE_KEY --fileshare --upload g4databases g4db Test2
```
WARNING: All files contained in Test2 will be copied directly in g4db: 
cannot specify subdirectory in file-share. At this point it is best one of
these two options:
 1. Put content of the directory to update in a new empty directory
    and upload that dir with a single sub-directory
 2. It could make sense to create separate file-shares for each DB directory
    this causes a complication in the docker run command since each should
    be passed as a separate data-volume, the problem is the version number
    that depends on the G4 version

### Download results from a storage container
To get the list of files in a storage blob container (remember to setup `AZURE_STORAGE_KEY` and
`AZURE_STORAGE_ACCOUNT`:
```
az storage blob list -c <blob-container> | jq -r '.[].name'
blobxfer $AZURE_STORAGE_ACCOUNT <blob-container> . --storageaccountkey $AZURE_STORAGE_KEY --remoteresource <file-to-download|.for all> --download
```
For example to download all cross sections files (called crosssections*.tgz):
```
blobxfer $AZURE_STORAGE_ACCOUNT <blob-container> . --storageaccountkey $AZURE_STORAGE_KEY --remoteresource . --download --include 'crosssections*.tgz'
```


