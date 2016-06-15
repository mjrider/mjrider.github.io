#!/bin/bash

set -e 

DNSLINK="$1"

if [ -z ${CFUSER} ] ; then
	echo "CFUSER not set"
	exit 1;
fi

if [ -z ${CFKEY} ] ; then
	echo "CFKEY not set"
	exit 1;
fi
if [ -z ${ZONE} ] ; then
	echo "ZONE not set"
	exit 1;
fi
if [ -z ${RECORD} ] ; then
	echo "RECORD not set"
	exit 1;
fi

if [ -z ${DNSLINK} ] ; then
	echo "no dnslink supplied"
	exit 1;
fi
DNSLINK="dnslink=${DNSLINK}"

# LOGGER
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" 
    fi
}

# SCRIPT START
log "Check Initiated"

zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | json -c 'this.success==true' 'result[0].id')


if [ -z "${zone_identifier}" ] ; then
	echo "zone not found"
	exit
fi

record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$RECORD" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | json -c 'this.success==true' result | json -a -c '/^dnslink=/.test(this.content)' id  )

if [ -z "${record_identifier}" ] ; then
	echo "record not found"
	exit 
fi

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"TXT\",\"name\":\"$RECORD\",\"content\":\"${DNSLINK}\"}" )

if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    exit 1 
else
	message="update successfull"
    log "$message"
fi
