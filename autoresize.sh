#!/bin/bash

#Get parameters from json configuration files
if [ ! -e pool.json ];then
     echo "Cannot find pool.json file in current directory"
     exit 1
fi
if [ ! -e credentials.json ];then
    echo "Cannot find credentials.json file in current directory"
    exit 1
fi
if [ ! -e summary.json ];then
    echo "Cannot find summary.json file in current directory"
    exit 1
fi

export AZURE_BATCH_POOL_ID=`jq -r '.pool_specification.id' pool.json`
export AZURE_BATCH_ACCOUNT=`jq -r '.credentials.batch.account' credentials.json`
export AZURE_BATCH_ACCESS_KEY=`jq -r '.credentials.batch.account_key' credentials.json `
export AZURE_BATCH_ENDPOINT=`jq -r '.credentials.batch.account_service_url' credentials.json`

#Get number of running nodes
newnum=`az batch node list --pool-id $AZURE_BATCH_POOL_ID --query '[].id' --filter "state eq 'running'" --out tsv | wc -l`
echo "Number of running nodes: $newnum"
while [ $newnum -gt 1 ];do
      #Check if number is the same as requested
      currentnodes=`jq -r '.pool_specification.vm_count.dedicated' pool.json`
      echo "Requested $currentnodes nodes"
      if [ $newnum -lt $currentnodes ];then
            echo "Some nodes idle, resize"
            #Some nodes are idle, resize
            mv pool.json pool.original.json
            jq --argjson numjobs ${newnum} '.pool_specification.vm_count.dedicated=$numjobs' pool.original.json > pool.json
            az-batch resize summary.json
      fi
      newnum=`az batch node list --pool-id $AZURE_BATCH_POOL_ID --query '[].id' --filter "state eq 'running'" --out tsv | wc -l`
      echo "Now there are $newnum running nodes. Sleep for 60 minutes"
      sleep 60m
done
echo "Max one running node left, waiting for jobs to finish"
running=`az-batch status jobs summary.json | grep state | grep -v completed | wc -l`
while [ $running -gt 0 ];do
      echo "Still $running jobs"
      #Still jobs running
      sleep 30m
      running=`az-batch status jobs summary.json | grep state | grep -v completed | wc -l`
done
echo "Ok, no more jobs. Terminate pool"
az-batch terminate -y summary.json


