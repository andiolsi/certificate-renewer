FROM alpine:latest

WORKDIR /certificate-renewer

COPY scripts/* ./


RUN apk add --update-cache bash openssl ca-certificates python3 py3-pip nginx nodejs gcc python3-dev libc-dev libffi libffi-dev certbot npm


RUN pip3 install certbot-ext-auth
RUN npm install 


ENTRYPOINT [ "/certificate-renewer/entrypoint.sh" ]
