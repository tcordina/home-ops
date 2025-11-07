#!/bin/bash

kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io longhorn-admission-webhook
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io longhorn-admission-webhook

for crd in $(kubectl get crd -o name | grep longhorn.io); do
  kubectl get $crd -n longhorn-system -o name | while read resource; do
    kubectl patch $resource -n longhorn-system --type=merge -p '{"metadata":{"finalizers":[]}}'
    kubectl delete $resource -n longhorn-system
  done
  kubectl delete $crd
done
