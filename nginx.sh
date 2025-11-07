#!/bin/bash

CA=$(kubectl -n ingress-nginx get secret ingress-nginx-admission -ojsonpath='{.data.ca}')
kubectl patch validatingwebhookconfigurations ingress-nginx-admission -n ingress-nginx --type='json' -p='[{"op": "add", "path": "/webhooks/0/clientConfig/caBundle", "value":"'$CA'"}]'