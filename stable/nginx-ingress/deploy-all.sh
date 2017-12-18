#! /usr/bin/env bash

echo "deploy namespace first"
kubectl apply -f namespace.yaml 

echo "install ingress controller by using helm"
helm install --namespace b2b-compass \
    -f values.yaml \
    --name b2b-compass-ingress-ctrl \
    --set controller.publishService.enabled="true" \
    --set controller.scope.enabled="true" \
    --set controller.rbac.create="true" \
    --set controller.defaultSSLCertificate="b2b-compass/b2b-compass-cert"\
    --set rbac.create="true" \
    stable/nginx-ingress

echo "TLS - create tls self-signed secret"
echo 'TLS - create certs dir'
mkdir -p certs

echo 'TLS - clear old files'
rm certs/* -R

echo 'TLS - create the server key and certificate for the related CN'
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt -subj "/CN=b2b-compass.aws-0070.cloudfirst.digital"

echo "TLS - apply secret to k8s"
kubectl create secret tls --cert=certs/server.crt --key=certs/server.key b2b-compass-cert --namespace b2b-compass

echo "deploy nginx deployment"
kubectl apply -f nginx-sample/nginx-deployment.yaml

echo "deploy nginx service"
kubectl apply -f nginx-sample/nginx-svc.yaml

echo "deploy nginx tls-based ingress rule"
kubectl apply -f nginx-sample/nginx-ingress.yaml
