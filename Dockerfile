FROM alpine:latest


RUN apk add --update-cache bash openssl ca-certificates certbot bash tzdata coreutils curl bind-tools jq
RUN mkdir /scripts
RUN mkdir /posthooks
RUN mkdir /prehooks
COPY scripts/* /scripts
COPY prehooks/* /prehooks
COPY posthooks/* /posthooks

CMD ["/bin/bash"]

