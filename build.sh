#!/usr/bin/env bash
VERSION=${VERSION:-v1.0.0}
docker build -t andiolsi/certificate-renewer:${VERSION} -t andiolsi/certificate-renewer:latest  ./
 
