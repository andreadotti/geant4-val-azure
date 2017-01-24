#!/bin/bash

if [ $# -lt 1 ];then 
    echo "usage: "$0" <physicslist>"
    exit 1
fi
pl=$1

host_db=/home/adotti/Work/share/G4data

all_macros=`docker run -v"${host_db}:/usr/local/geant4/data:ro" --rm andreadotti/geant4-val:latest find validation -name run.mac`

cat <<EOF > .singleinteractions-${pl}-list.json 
 {                                                                                                                                                                              "singleinteractions-${pl}" : [
EOF

for macro in $all_macros;do
        echo "      \"/runme.sh $pl $macro\"," >> .singleinteractions-${pl}-list.json
done
sed '$ s/.$//' .singleinteractions-${pl}-list.json > singleinteractions-${pl}-list.json
rm .singleinteractions-${pl}-list.json
echo "   ]" >> singleinteractions-${pl}-list.json
echo "}" >> singleinteractions-${pl}-list.json
