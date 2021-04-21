#!/usr/bin/env bash
if [ -z "${CLOUDFLARE_API_TOKEN}" ]
then
    echo "Variable CLOUDFLARE_API_TOKEN is not set" >> /dev/stderr
    exit 1
fi

CLOUDFLARE_NAMESERVER="${CLOUDFLARE_NAMESERVER:-molly.ns.cloudflare.com}"

# Strip only the top domain to get the zone id
DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
if [ -z "${DOMAIN}" ]
then
    # if domain is empty it was not a subdomain
    DOMAIN="${CERTBOT_DOMAIN}"
fi

# Get the Cloudflare zone id
ZONE_EXTRA_PARAMS="status=active&page=1&per_page=20&order=status&direction=desc&match=all"

ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN&$ZONE_EXTRA_PARAMS" \
     -H     "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H     "Content-Type: application/json" |  jq -r  '.result[0].id')

# Create TXT record
CREATE_DOMAIN="_acme-challenge.$CERTBOT_DOMAIN"
RECORD_ID=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
     -H     "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H     "Content-Type: application/json" \
     --data '{"type":"TXT","name":"'"$CREATE_DOMAIN"'","content":"'"$CERTBOT_VALIDATION"'","ttl":120}' \
             |  jq -r  '.result.id')
# Save info for cleanup
if [ ! -d /tmp/CERTBOT_$CERTBOT_DOMAIN ];then
        mkdir -m 0700 /tmp/CERTBOT_$CERTBOT_DOMAIN
fi
echo $ZONE_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID
echo $RECORD_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID


resolved=0
count=0
while [  $resolved -ne 1 ]
do
    dig ${CREATE_DOMAIN} TXT  @${CLOUDFLARE_NAMESERVER} | grep -q $CERTBOT_VALIDATION
    if [ $? -eq 0 ]
    then
        resolved=1
    else 
        let count++
        if [ $count -lt 12 ]
        then
            sleep 5
        else
            echo "Failed to read txt record ${CREATE_DOMAIN} from ${CLOUDFLARE_NAMESERVER}"   >> /dev/stderr
            exit 1            
        fi
    fi
done
