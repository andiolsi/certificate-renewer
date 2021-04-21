#FROM debian:stretch-slim
#
#RUN set -x \
#&& apt-get update \
#&& apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates \
#&& apt-get install -y \
#                    curl \
#                    python3 \
#                    python3-pip \
#                    certbot \
#                    jq \
#                    dnsutils \
#&& apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/* \
#&& apt-get purge -y --auto-remove 
#
#STOPSIGNAL SIGQUIT

FROM alpine:latest


RUN apk add --update-cache bash openssl ca-certificates certbot bash tzdata coreutils curl
RUN mkdir /scripts
RUN mkdir /posthooks
COPY scripts/* /scripts
COPY posthooks/* /posthooks

CMD ["/bin/bash"]

