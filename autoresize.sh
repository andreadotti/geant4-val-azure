#!/bin/bash

#Get parameters from json configuration files
if [ ! -a pool.json ];then
     echo "Cannot find pool.json file in current directory"
     exit 1
fi
if [ ! -a credentials.json ];then
    echo "Cannot find credentials.json file in current directory"
    exit 1
fi
if [ ! -a summary.json ];then
    echo "Cannot find summary.json file in current directory"
    exit 1
fi

export AZURE_BATCH_POOL_ID=`jq -r '.pool_specification.id' pool.json`
export AZURE_BATCH_ACCOUNT=`jq -r '.credentials.batch.account' credentials.json`
export AZURE_BATCH_ACCESS_KEY=`jq -r '.credentials.batch.account_key' credentials.json `
export AZURE_BATCH_ENDPOINT=`jq -r '.credentials.batch.account_service_url' credentials.json`

#Get number of running nodes
newnum=`az batch node list --pool-id $AZURE_BATCH_POOL_ID --query '[].id' --filter "state eq 'running'" --out tsv | wc -l`
while [ $newnum -gt 1 ];do
      #Check if number is the same as requested
      currentnodes=`jq -r '.pool_specification.vm_count.dedicated' pool.json`
      if [ $newnum -lt $currentnodes ];then
            #Some nodes are idle, resize
            mv pool.json pool.original.json
            jq --argjson numjobs ${newnum} '.pool_specification.vm_count.dedicated=$numjobs' > pool.json
            az-batch resize summary.json
            echo "Sleep for 60 minutes"
            sleep 60m
      fi
      newnum=`az batch node list --pool-id $AZURE_BATCH_POOL_ID --query '[].id' --filter "state eq 'running'" --out tsv | wc -l`
done
