#!/usr/bin/env bash
VERSION=${VERSION:-1.1.3}
docker build -t andiolsi/certificate-renewer:${VERSION} -t andiolsi/certificate-renewer:latest  ./
docker push andiolsi/certificate-renewer:${VERSION}
docker push andiolsi/certificate-renewer:latest
