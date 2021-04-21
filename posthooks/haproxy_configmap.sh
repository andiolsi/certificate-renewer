#!/usr/bin/env bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# debug mode
DEBUG=${DEBUG:-}
[ ! -z "${DEBUG}" ] && set -x

_errs=0

DOMAIN="$1"
CERTDIR="$2"
TMPDIR="/tmp/${RANDOM}"
mkdir -p "${TMPDIR}"
cat "${CERTDIR}"/fullchain.pem "${CERTDIR}"/privkey.pem > "${TMPDIR}"/${DOMAIN}.combined.pem 


TARGET_CONFIGMAP="${TARGET_CONFIGMAP:-}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-default}"

# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc.cluster.local

# Path to ServiceAccount token
SERVICEACCOUNT=${SERVICEACCOUNT:-/var/run/secrets/kubernetes.io/serviceaccount}

if [ ! -d "${SERVICEACCOUNT}" ]
then
    echo "No service account directory found at '${SERVICEACCOUNT}'."
    let _errs++
else

    # Read this Pod's namespace
    NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

    # Read the ServiceAccount bearer token
    TOKEN=$(cat ${SERVICEACCOUNT}/token)

    # Reference the internal certificate authority (CA)
    CACERT=${SERVICEACCOUNT}/ca.crt

    if [ -z "${TARGET_CONFIGMAP}" ]
    then
        echo "Could not read target configmap from '${TARGET_CONFIGMAP}'."
        let _errs++
    fi
    if [ -z "${NAMESPACE}" ]
    then
        echo "Could not read namespace from '${SERVICEACCOUNT}/namespace'."
        let _errs++
    fi
    if [ -z "${TOKEN}" ]
    then
        echo "Could not read token from '${SERVICEACCOUNT}/token'."
        let _errs++
    fi
    if [ -z "${CACERT}" ]
    then
        echo "Could not read token from '${SERVICEACCOUNT}/ca.crt'."
        let _errs++
    fi
fi

if [ ${_errs} -ne 0 ]
then
    echo "encountered ${_errs} errors during preflight check, please check above output for error messages"
 #   rm -rf "${TMPDIR}"
    exit 1
fi


set -e 
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -H 'Accept: application/json' ${APISERVER}/api/v1/namespaces/${TARGET_NAMESPACE}/configmaps/${TARGET_CONFIGMAP} -H 'Content-Type: application/strategic-merge-patch+json' -X PATCH  -d "{\"data\": { \"${DOMAIN}.combined.pem\" : \"$(cat ${TMPDIR}/${DOMAIN}.combined.pem  | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')\"}}" 
#rm -rf "${TMPDIR}"