#certificate-renewer

Not indended to be a detailed guide or documentation. 
The correct person may save themselves a couple of hours of work though.


https://github.com/andiolsi/certificate-renewer

- I want to generate and renew certificates for all my domains and have them signed by letsencrypt.
- I want to have wildcard certificates
- I want to automate this process so i dont need to manually set TXT records or create acme files
- I want to generate combined.pem files and write them into a kubernetes configMap so haproxy can read them


The solution uses Cloudflare DNS API to create the TXT records, certbots manual hooks to trigger API calls and some good old BaSH to tie it together.

Stuffed inside a docker container and deployed in my kubernetes cluster I will never have to manually renew my certificates again. 

A haproxy sidecar container checks for modifications in certificates and SIGHUPs its haproxy daemon, but thats out of scope here.


Environment variables (as set on my kubernetes deployment):

CERTIFICATE_DOMAIN_LIST: Is semicolon seperated list of comma seperated domains.  (Wildcard domains follow the main domain and will be stuffed in the same folder by certbot   *.domain-one.net will thus end up in live/domain-one.net).

PREHOOK_SCRIPT: Script that will be called before a certificate is even checked for existence or validtity.  (Use it to copy from configMap to emptyDir)
POSTHOOK_SCRIPT: Script that will be called when a certificate was generated or renewed.  configmap.sh is deployed with this image.

Example deployment :
```
global_certificate_renewer_deployment:
  manifest:
    metadata:
      name: certificate-renewer
      namespace: default
      labels:
        run: certificate-renewer
    spec:
      replicas: 1
      selector:
        matchLabels:
          run: certificate-renewer
      template:
        metadata:
          labels:
            run: certificate-renewer
        spec:          
          serviceAccountName: certificate-renewer
          restartPolicy: Always
          volumes:
            - name: certificate-renewer-crontabs-volume
              configMap:
                name: certificate-renewer-crontabs
            - name: certificate-renewer-certificates-volume
              configMap:
                name: certificate-renewer-certificates
            - name: certificate-renewer-workdir-volume
              emptyDir: {}
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: nodeselector/olsitec
                    operator: In
                    values:
                      - "true"                   
          containers:
            - name: certificate-renewer
              image: andiolsi/certificate-renewer:latest
              imagePullPolicy: Always
              volumeMounts:                
                - name: certificate-renewer-crontabs-volume
                  mountPath: /etc/crontabs         
                - name: certificate-renewer-certificates-volume
                  mountPath: /source-certificates
                - name: certificate-renewer-workdir-volume
                  mountPath: /certificate-workerdir
              command: ['sh', '-c', 'crond -c /etc/crontabs -d 8 -f']
              env:
                - name: TZ
                  value: "{{default_timezone}}"
                - name: CERTIFICATE_DOMAIN_LIST
                    value: "domain-one.local,*.domain-one.local;domain-two.local,*.domain-two.local"
                - name: EMAIL
                    value: myemail@example.local
                - name: CLOUDFLARE_API_TOKEN
                  valueFrom:
                    secretKeyRef:
                      name: certificate-renewer-credentials
                      key: CLOUDFLARE_API_TOKEN
                - name: PREHOOK_SCRIPT
                  value: /prehooks/copy_certificates.sh
                - name: CERTIFICATE_SOURCE_DIRECTORY
                  value: /source-certificates                
                - name: POSTHOOK_SCRIPT
                  value: /posthooks/configmap.sh
                - name: TARGET_CONFIGMAP
                  value: haproxy-certificates
                - name: TARGET_NAMESPACE
                  value: default
```


```
global_certificate_renewer_configmaps:
  - manifest:
      metadata:
        name: certificate-renewer-crontabs
        namespace: default
      data:
        root: |
          0 6 * * * /bin/bash /scripts/check_validity.sh > /dev/stdout 2>&1
  - manifest:
      metadata:
        name: certificate-renewer-certificates
        namespace: default

        
```

```
global_certificate_renewer_serviceaccount:
  manifest:
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: certificate-renewer
      namespace: default

global_certificate_renewer_roles:
  - manifest:
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
          name: certificate-renewer
          namespace: default
      rules:
      - apiGroups:
        - extensions
        - apps
        - ""
        resources:
        - configmaps      
        verbs:
        - get
        - patch
        - list

global_certificate_renewer_rolebindings:
  - manifest:
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: certificate-renewer
        namespace: default      
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: certificate-renewer
      subjects:
      - kind: ServiceAccount
        name: certificate-renewer
        namespace: default
````