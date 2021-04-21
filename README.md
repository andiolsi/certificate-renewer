#certificate-renewer

- I want to generate and renew certificates for all my domains and have them signed by letsencrypt.
- I want to have wildcard certificates
- I want to automate this process so i dont need to manually set TXT records or create acme files
- I want to generate combined.pem files and write them into a kubernetes configMap so haproxy can read them


The solution uses Cloudflare DNS API to create the TXT records, certbots manual hooks to trigger API calls and some good old BaSH to tie it together.

Stuffed inside a docker container and deployed in my kubernetes cluster I will never have to manually renew my certificates again. 

A haproxy sidecar container checks for modifications in certificates and SIGHUPs its haproxy daemon, but thats out of scope here.


Environment variables (as set on my kubernetes deployment):

CERTIFICATE_DOMAIN_LIST: Is semicolon seperated list of comma seperated domains.  (Wildcard domains follow the main domain and will be stuffed in the same folder by certbot   *.domain-one.net will thus end up in live/domain-one.net).

POSTHOOK_SCRIPT: Script that will be called when a certificate was generated or renewed.  haproxy_configmap.sh is deployed with this image.

```
- name: CERTIFICATE_DOMAIN_LIST
    value: "domain-one.local,*.domain-one.local;domain-two.local,*.domain-two.local"
- name: EMAIL
    value: myemail@example.local
- name: CLOUDFLARE_API_TOKEN
    valueFrom:
    secretKeyRef:
        name: certificate-renewer-credentials
        key: CLOUDFLARE_API_TOKEN
- name: POSTHOOK_SCRIPT
    value: /posthooks/haproxy_configmap.sh
- name: TARGET_CONFIGMAP
    value: haproxy-certificates
- name: TARGET_NAMESPACE
    value: default

```
