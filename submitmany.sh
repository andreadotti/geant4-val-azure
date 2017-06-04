#!/bin/bash

cli="az-batch"
defaultsummary="summary.json"
joblimit=20

function submit {
  if [ $# -lt 2 ];then 
     echo "usage: $0 <jobname> <summaryfile.json>"
     return
  fi
  $cli submit -r $1 $2
}

function countactivejobs {
  if [ $# -lt 1 ];then
     echo "usage: $0 <summaryfile.json>"
     return
  fi
  $cli status jobs $1 2>&1 | grep active | wc -l
}

function deljob {
  if [ $# -lt 2 ];then
     echo "usage: $0 <jobname> <summaryfile.json>"
     return
  fi
  $cli deljob -y -j $1 $2
}

function listjobs {
  if [ $# -lt 1 ];then
     echo "usage: $0 <summaryfile.json>"
     return
  fi
  $cli status jobs $1 2>&1 | awk '{print $5}' | sed 's/job_id=//g'
}

function jobstatus {
  if [ $# -lt 2 ];then
     echo "usage $0 <jobname> <summaryfile.json>"
     return
  fi
  #check if job is finised (no running or waiting, only completed)
  #print number of completed else -1
  $cli status -j $1 $2 | awk '{if ($3 > 0 && $5 == 0 && $7 ==0) {print $3} else {print -1} } '
}

function usage {
  echo "usage: $1 [-c summaryfile.json] <job1> [<job2> [<job3> ..]]"
  exit 1 
}

summaryfile=$defaultsummary
while getopts ":j" o;do
     case "$o" in
        j)
	  summaryfile=${OPTARG}
	  ;;
        *)
          usage
	  ;;
     esac
done
shift $((OPTIND-1))

if [ $# -lt 1 ];then
   usage $0
fi

for jj in "$@";do
    printf "%s - Submitting job: $s\n" "`date`" "$jj"
    #Check number of active jobs
    while [ 1 -eq 1 ];do
       num=`countactivejobs $summaryfile`
       if [ $num -lt $joblimit ];then 
	  break
       fi
       printf "%s - Maximum number of active jobs reaced, sleeping 30 mins\n" "`date`" 
       sleep 30m
    done #Infinte loop 
    submit $jj $summaryfile
done
