#!/usr/bin/env bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# debug mode
DEBUG=${DEBUG:-}
[ ! -z "${DEBUG}" ] && set -x


MINIMUM_VALIDITY_DAYS=${MINIMUM_VALIDITY_DAYS:-29}
MINIMUM_VALIDITY_SECONDS=${MINIMUM_VALIDITY_SECONDS:-$((${MINIMUM_VALIDITY_DAYS} * 24 * 60 * 60))}
if [ -z "${CLOUDFLARE_API_TOKEN}" ]
then
    echo "Variable CLOUDFLARE_API_TOKEN is not set" >> /dev/stderr
    exit 1
fi

if [ -z "${EMAIL}" ]
then
    echo "Variable EMAIL is not set" >> /dev/stderr
    exit 1
fi

if [ -z "${CERTIFICATE_DOMAIN_LIST}" ]
then
    echo "Variable CERTIFICATE_DOMAIN_LIST is not set" >> /dev/stderr
    exit 1
fi

CERTBOT_WORKDIR="${CERTBOT_WORKDIR:-/etc/letsencrypt}"

OLDIFS=$IFS
IFS=';' read -r -a ARRAY_CERTIFICATE_DOMAIN_LIST <<< "$CERTIFICATE_DOMAIN_LIST"
IFS=$OLDIFS


function generate_cert () {
    echo "generating certificates for domains: $1"
    certbot certonly --manual --preferred-challenges=dns --manual-auth-hook=/scripts/authenticator.sh --manual-cleanup-hook=/scripts/cleanup.sh  -m "${EMAIL}"  -d "$1" --agree-tos -n --manual-public-ip-logging-ok
}
function check_validity () {
    _ENDDATE=$(openssl x509 -in "$1" -noout -enddate | cut -d= -f 2)
    _ENDDATE_EPOCH=$(date --date "${_ENDDATE}" +%s)
    _NOWDATE_EPOCH=$(date +%s)
    # check if the certificate is valid longer than NOW + MINUM_VALIDITY
    if [ ${_ENDDATE_EPOCH} -gt $((${_NOWDATE_EPOCH} + ${MINIMUM_VALIDITY_SECONDS})) ]
    then
        echo 0
    else
        echo 1
    fi
}
for CERTBOT_DOMAIN in ${ARRAY_CERTIFICATE_DOMAIN_LIST[@]}
do
    DOMAIN=$(expr match "${CERTBOT_DOMAIN}" '.*\.\(.*\..*\)')
    if [ -z "${DOMAIN}" ]
    then        
        DOMAIN="${CERTBOT_DOMAIN}"
    fi
    echo "###########   $DOMAIN    ##########"

    if [ -d "${CERTBOT_WORKDIR}/live/${DOMAIN}" ] && [ -f "${CERTBOT_WORKDIR}/live/${DOMAIN}/cert.pem" ]
    then
        if [[ "$(check_validity ${CERTBOT_WORKDIR}/live/${DOMAIN}/cert.pem)" != 0 ]]
        then
            echo "certificate validity below expiry threshold, renewing it"
            generate_cert "${CERTBOT_DOMAIN}"
            
            if [ ! -z "${POSTHOOK_SCRIPT}" ]
            then
                /bin/bash "${POSTHOOK_SCRIPT}" "${DOMAIN}" "${CERTBOT_WORKDIR}/live/${DOMAIN}"
            fi
        else
            echo "certificates validity exceeds expiry threshold, keeping it"
        fi
    else
        echo "directory '${DOMAIN}' for '${CERTBOT_DOMAIN}' does not exist at '${CERTBOT_WORKDIR}/live/${DOMAIN}', creating new certificates"
        generate_cert "${CERTBOT_DOMAIN}"
    fi
done