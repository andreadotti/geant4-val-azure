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
    printf "%s : Submitting job: $s\n" "`date`" "$jj"
    #Check number of active jobs
    break_loop=0
    while [ $break_loop -eq 0 ];do
       break_loop=1
       num=`countactivejobs $summaryfile`
       if [ $num -ge $joblimit ];then
          break_loop=0
          printf "%s : Limit on number of active jobs reached, check for completed jobs\n" "`date`"
	  #No more slots available, loop on jobs, search 
          #the first that has finised
          jobs=`listjobs $summaryfile`
	  
          for jj_run in $jobs;do
	    running=`jobstatus $jj_run $summaryfile`
	    if [ $running -gt 0 ];then
	 	printf "%s : Job %s is completed, deleting it\n" "`date`" "${jj_run}"
		deljob $jj_run $summaryfile 
 		break_loop=1
		break;
	    fi
          done
       #Wait for 30 mins
       [ $break_loop -eq 0 ] && sleep 30m
       fi
    done #Infinte loop 
    submit $jj $summaryfile
done
