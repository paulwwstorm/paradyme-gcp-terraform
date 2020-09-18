#!/usr/bin/env bash

## GCloud Initial Setup
#
https://console.cloud.google.com/

# Set GCloud Project
gcloud config set project general-pipeline-jedi

# Set Region
gcloud config set compute/zone us-east4

# Create GKS Cluster
gcloud container clusters create general-pipeline-jedi --num-nodes=1 \
  --enable-autoscaling --min-nodes=1 --max-nodes=4 \
  --machine-type=n1-standard-2 --labels=name=general-pipeline-jedi \
  --node-labels=name=general-pipeline-jedi-node

# Set local credentials for kubectl access
gcloud container clusters get-credentials general-pipeline-jedi

###
# Setup Helm for Deployments
# Create tiller service account and bind to ClusterAdmin Role.
kubectl apply -f  ./kubernetes/helm-service-account.yaml

helm init --wait --service-account tiller

helm repo update

# If need to check deployment
#kubectl get pod --namespace kube-system

# Install nginx ingress
kubectl create namespace nginx-ingress
helm install stable/nginx-ingress --name nginx --namespace kube-system

###
# DNS Setup - Configure nginx ingress loadbalancer in Domains, for external access to a specific domain.
# Retrieve nginx-ingress-service from kubectl
# NOTE - For long running cluster, change VPC External IP address to static
kubectl --namespace kube-system get service nginx-nginx-ingress-controller --output json

## Alternate approach to the above is two part:
# gcloud compute addresses create my-static-ip-address --region us-east4
# helm install --name nginx-ingress stable/nginx-ingress \
#   --namespace my-namespace --set controller.service.loadBalancerIP=${CREATED_STATIC_IP}
##

## MANUAL SETUP OF DNS Entry
# Example of deploying ingress routes on route53
#  resource "aws_route53_record" "nginx" {
#    zone_id = data.aws_route53_zone.selected.zone_id
#    name    = "*.${var.cluster-name}.${var.cluster-dns-name}"
#    type    = "A"
#    alias {
#      name = "dualstack.${data.external.nginx-ingress-service.result.hostname}"
#      zone_id = data.aws_elb_hosted_zone_id.main.id
#      evaluate_target_health = false
#    }
#  }

## Install cert-manager for browser trust certificate
# GKE specific security configuration
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

# Install cert-manager
kubectl apply --validate=false \
  -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager-legacy.yaml

# Apply cluster issuer yaml for cert-manager and apply to cluster
kubectl apply -f ./kubernetes/cluster-issuer.yaml
kubectl apply -f ./kubernetes/cluster-issuer-prod.yaml

# If need to check deployment
# kubectl get pods --namespace cert-manager


###
# Data Flow Deployment
helm install --name jedi-pipes  \
  --set kafka.enabled=true,rabbitmq.enabled=false,kafka.persistence.size=20Gi \
  --set features.monitoring.enabled=true \
  --set server.service.type=ClusterIP \
  --set grafana.service.type=ClusterIP \
  --set prometheus.proxy.service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.protocol=http \
  --set server.service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.protocol=http \
  stable/spring-cloud-data-flow

#  --set ingress.server.host=dataflow.jedi.paradymelabs.com \
#  --set ingress.grafana.host=grafana.jedi.paradymelabs.com \

# Data Flow Dashboard Ingress
# Need to clean up attempted Ingress deploy
kubectl apply -f ./kubernetes/scdf-dashboard-ingress.yaml
# Address https://dataflow.jedi.paradymelabs.com/dashboard

# Grafana Ingress
kubectl apply -f ./kubernetes/grafana-ingress.yaml
# Address https://grafana.jedi.paradymelabs.com/login

# Prometheus Ingress
kubectl apply -f ./kubernetes/prometheus-ingress.yaml
# Address https://prometheus.jedi.paradymelabs.com/graph

# If need to check certificate status
# kubectl get certificate


# Change Grafana to use Persistent Storage
kubectl apply -f ./kubernetes/grafana-persistentvolumeclaim.yaml

kubectl patch deployment jedi-pipes-grafana --patch "$(cat ./kubernetes/grafana-deployment.yaml)"

kubectl get pod
kubectl exec --stdin --tty ${grafana-pod} -- /bin/bash
bin/grafana-cli plugins install digrich-bubblechart-panel
bin/grafana-cli plugins install grafana-piechart-panel
exit

kubectl scale deploy jedi-pipes-grafana --replicas=0
kubectl scale deploy jedi-pipes-grafana --replicas=1
# Or just delete existing grafana pod

# Deploy to Grafana
twitter-analysis-dashboard.json


## Pipeline Autoscaling Deployments
kubectl apply -f https://raw.githubusercontent.com/spring-cloud/spring-cloud-dataflow-samples/master/dataflow-website/recipes/scaling/kubernetes/helm/alertwebhook/alertwebhook-svc.yaml
kubectl apply -f ./kubernetes/alertwebhook-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/spring-cloud/spring-cloud-dataflow-samples/master/dataflow-website/recipes/scaling/kubernetes/alertmanager/prometheus-alertmanager-service.yaml
kubectl apply -f https://raw.githubusercontent.com/spring-cloud/spring-cloud-dataflow-samples/master/dataflow-website/recipes/scaling/kubernetes/alertmanager/prometheus-alertmanager-deployment.yaml

## Update prometheus-alertmanager-configmap.yaml w/ alertwebhook LB Address
kubectl apply -f ./kubernetes/prometheus-alertmanager-configmap.yaml
kubectl patch cm jedi-pipes-prometheus-server --patch "$(cat ./kubernetes/prometheus-configmap.yaml)"


### Data Flow Operation
# Data Flow CLI
# java -jar ../spring-cloud-dataflow-shell-2.5.1.RELEASE.jar \
#   --dataflow.uri=https://dataflow.jedi.paradymelabs.com

# App Import
# dataflow:>app import --uri https://dataflow.spring.io/kafka-docker-latest

# Review Deployed Apps
# kubectl get pods -l role=spring-app

# Access Application Logs
# kubectl logs -f deployment/words-log-v1


## Claim Analysis
dataflow:>app register --type source --name claim-generator-source --uri docker://lmcginty/demo:claim-generator-source

dataflow:>stream create claim-stream --definition "claim-generator-source | log"

dataflow:>stream create claim-metrics --definition ":claim-stream.claim-generator-source > counter --counter.name=claim --counter.tag.expression.claim=payload"


## Scaling test deployment
#dataflow:>stream create --name scaletest --definition "time --fixed-delay=995 --time-unit=MILLISECONDS | transform --expression=\"payload + '-' + T(java.lang.Math).exp(700)\" | log"
dataflow:>stream create --name scale-demo --definition "time --fixed-delay=995 --time-unit=MILLISECONDS | transform --expression=\"payload + '-' + T(java.lang.Math).exp(700)\" | log"

dataflow:>stream deploy --name scale-demo --properties "app.time.producer.partitionKeyExpression=payload,app.transform.spring.cloud.stream.kafka.binder.autoAddPartitions=true,app.transform.spring.cloud.stream.kafka.binder.minPartitionCount=8"

dataflow:>stream update --name scale-demo --properties "app.time.trigger.time-unit=MICROSECONDS"


## Twitter Analysis
dataflow:>stream create tweets --definition "twitterstream --consumerKey=l80hmfFrJNIVFhmfuHo9raBhF --consumerSecret=U12T6nQncmeyju5YYgrdPa5mLLe4SScZEuJEATXC9pLDomFhid --accessToken=1275494146984366082-KazTC3seSZgPjQF6f2kIF8RU2WTaU4 --accessTokenSecret=Fg150CBQ2hkZZOTf6LmWZGqGpFwLYZykMfgwz474orCeW | log"

dataflow:>stream create tweetlang --definition ":tweets.twitterstream > counter --counter.name=language --counter.tag.expression.lang=#jsonPath(payload,'$..lang')" --deploy

dataflow:>stream create tagcount  --definition ":tweets.twitterstream > counter --counter.name=hashtags --counter.tag.expression.htag=#jsonPath(payload,'$.entities.hashtags[*].text')" --deploy






## Manual API Scale-out Call Examples
# https://dataflow.jedi.paradymelabs.com/streams/deployments/scale/scaletest/transform/instances/5
# https://dataflow.jedi.paradymelabs.com/streams/deployments/scale/tagcount/counter/instances/2



###
## Cleanup/Destroy SCDF Deployment
# helm delete jedi-pipes --purge

## Cleanup/Destroy GKS Cluster
# FINAL: gcloud container clusters delete general-pipeline-jedi
###