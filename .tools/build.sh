#!/bin/bash

#wait till we have a swarm
while [ `ipfs swarm peers 2> /dev/null | wc -l` -lt 8 ] ; do ipfs swarm peers ; echo 'Swarm to small... sleeping' ; sleep 10 ; done
echo "Swarm is fine:"
ipfs swarm peers

set -e 
rsync --update --verbose --progress -r --exclude=.travis.yml --exclude=output/ --exclude=.git ./ ./output
mkdir ./output/data/
mv ./output/data.json ./output/data/data.json

# rewrite links to staging website to /
find output -name \*.html -print0 | xargs -0 sed -i -e 's|(https?:)?//mjrider.github.io/|/|g'


#add all files
( cd output ; ipfs add -q -r -w ./ ) | tee /tmp/add-log.txt 

# get dir id
ID=`cat /tmp/add-log.txt | tail -n 1`

set -x 

# for 'debugging' for gateway to retrieve content
wget -O /dev/null -q "https://ipfs.muze.nl:1443/pin.php?hash=${ID}"
wget -O /dev/null -q https://gateway.ipfs.io/ipfs/${ID}/
wget -O /dev/null -q http://ipfs.muze.nl/ipfs/${ID}/
wget -O /dev/null -q https://gateway.ipfs.io/ipfs/${ID}/data/data.json
wget -O /dev/null -q http://ipfs.muze.nl/ipfs/${ID}/data/data.json

# public to ipns
/tmp/tools/dns-update.sh "/ipfs/${ID}"

