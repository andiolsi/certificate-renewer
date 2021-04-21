#!/usr/bin/env bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# debug mode
DEBUG=${DEBUG:-}
[ ! -z "${DEBUG}" ] && set -x

DOMAIN="$1"
TARGET_DIRECTORY="$2"

set -e 

if [ ! -f "${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.cert.pem" ]
then
    echo "FILE ${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.cert.pem does not exist"
    exit 1
fi
if [ ! -f "${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.privkey.pem" ]
then
    echo "FILE ${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.privkey.pem does not exist"
    exit 1
fi
if [ ! -d "${TARGET_DIRECTORY}/archive/${DOMAIN}" ]
then
    mkdir -p "${TARGET_DIRECTORY}/archive/${DOMAIN}"
fi
if [ ! -d "${TARGET_DIRECTORY}/live/${DOMAIN}" ]
then
    mkdir -p "${TARGET_DIRECTORY}/live/${DOMAIN}"
fi

cp "${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.cert.pem" "${TARGET_DIRECTORY}/archive/${DOMAIN}/cert1.pem"
cp "${CERTIFICATE_SOURCE_DIRECTORY}/${DOMAIN}.privkey.pem" "${TARGET_DIRECTORY}/archive/${DOMAIN}/privkey1.pem"

cd "${TARGET_DIRECTORY}/live/${DOMAIN}/"
ln -sf "../../archive/${DOMAIN}/cert1.pem" cert.pem
ln -sf "../../archive/${DOMAIN}/privkey1.pem" privkey.pem
