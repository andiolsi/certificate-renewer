#!/usr/bin/env bash
# This script will read a certain nodes (NODE_NAME) value (NODE_LABEL_VALUE) of a label (NODE_LABEL) and use it to copy textfile metrics for the prometheus node exporter.
# Files will be read from diectory METRIC_SOURCE_DIRECTORY and are named NODE_LABEL_VALUE.xy.prom and copied to METRIC_TARGET_DIRECTORY.
# Refer to the following URL to read more about accessing the kubernetes API
# https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# debug mode
DEBUG=${DEBUG:-}
[ ! -z "${DEBUG}" ] && set -x

cat /etc/resolv.conf

_errs=0

METRIC_SOURCE_DIRECTORY=${METRIC_SOURCE_DIRECTORY:-/metrics-source}
METRIC_TARGET_DIRECTORY=${METRIC_TARGET_DIRECTORY:-/metrics-target}

if [ ! -d "${METRIC_SOURCE_DIRECTORY}" ]
then
    echo "Could not open source directory METRIC_SOURCE_DIRECTORY at '${METRIC_SOURCE_DIRECTORY}'."
    let _errs++
fi

if [ ! -d "${METRIC_TARGET_DIRECTORY}" ]
then
    echo "Could not open target directory METRIC_TARGET_DIRECTORY at '${METRIC_TARGET_DIRECTORY}'."
    let _errs++
fi


NODE_NAME=${NODE_NAME:-}

if [ -z "${NODE_NAME}" ]
then
    echo "No NODE_NAME specified."
    let _errs++
fi

NODE_LABEL=${NODE_LABEL:-}

if [ -z "${NODE_LABEL}" ]
then
    echo "No NODE_LABEL specified."
    let _errs++
fi
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
    exit 1
fi


set -e 
NODE_LABEL_VALUE=$(curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/nodes/${NODE_NAME}|jq -r ".metadata.labels.\"${NODE_LABEL}\"")

if [ -z "${NODE_LABEL_VALUE}" ]
then
    echo "Could not read value from label '${NODE_LABEL}' for node '${NODE_NAME}'. Copying from 'default' configuration."
    NODE_LABEL_VALUE="default"
fi

cp "${METRIC_SOURCE_DIRECTORY}/${NODE_LABEL_VALUE}."* "${METRIC_TARGET_DIRECTORY}/"
chmod a+r "${METRIC_TARGET_DIRECTORY}"/*
exit 0