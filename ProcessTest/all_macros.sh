#!/bin/bash

if [ $# -lt 1 ];then 
    echo "usage: "$0" <physicslist> [<processName>]"
    exit 1
fi
pl=$1
pname=""
[ $# -ge 2 ]&& pname=$2

[ $# -ge 3 ]&& host_db=$3 || host_db=/geant4-sw/data

all_macros=`docker run -v "${host_db}:/usr/local/geant4/data:ro" --rm andreadotti/geant4-val:latest find validation/${pname} -name run.mac`

[ "X"${pname} == "X" ] && pname="all"
out_file=tasks-singleinteractions-${pl}-${pname}.json

cat <<EOF > .${out_file}
 {
    "singleinteractions-${pl}-${pname}" : [
EOF

for macro in $all_macros;do
        echo "      \"/runme.sh $pl $macro\"," >> .${out_file}
done
sed '$ s/.$//' .${out_file}> ${out_file} 
rm .${out_file}
echo "   ]" >> ${out_file}
echo "}" >> ${out_file} 
