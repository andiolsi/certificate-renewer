#!/usr/bin/env bash
VERSION=${VERSION:-v1.1.1}
docker build -t andiolsi/certificate-renewer:${VERSION} -t andiolsi/certificate-renewer:latest  ./
docker push andiolsi/certificate-renewer:${VERSION}
docker push andiolsi/certificate-renewer:latest
