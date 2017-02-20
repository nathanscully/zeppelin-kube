#!/bin/bash

echo ""
echo "We're going to set up your testing environment. Enter to accept (defaults)"
echo ""
echo "What's the tag of the docker image you built? (latest)"
read tag
echo ""

# Set defaults if no input
if [[ -z "$tag" ]]; then
  tag="latest"
  fi

# debug
# echo $tag
# sleep 20

# Allow user to verify correct versions before deploying
echo ""
echo "##### We're going to setup with this version #####"
echo ""
echo "oneflare/insights-zeppelin-spark:$tag"


echo ""
echo "Does this look correct? (y/n)"
read -n 1 -s correct

# Exit on 'no'
if [[ $correct == 'n' ]]; then
  exit
fi

sleep 1

echo ""
echo "##### Creating namespace and setting up kubectl #####"
echo ""
# Create new namespace for branch
kubectl create namespace $tag

# Set kubectl context so you don"t have to append --namespace to commands
kubectl config set-context $tag \
  --cluster=insights.k8s-staging.oneflare.io \
  --namespace=$tag \
  --user=insights.k8s-staging.oneflare.io
kubectl config use-context $tag
echo ""
echo "##### Creating dependencies #####"
echo ""

# Create secrets
echo "##### Secrets..."
kubectl create -f secrets/dockerhub.yaml
kubectl create -f secrets/zeppelin-deploy-secrets.yaml

# Create storage definition and persistent volume claim
echo "##### Storage..."
kubectl create -f storage/aws-ebs.yaml
kubectl create -f storage/zeppelin-pvc.yaml
sleep 5

# Copy default conf files to persistent volume
echo "##### Creating job to copy default conf..."
cat jobs/zeppelin-copy-config.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
echo ""
echo "##### Waiting 1 minute for job to complete #####"
echo ""
sleep 60

# Delete job
echo "##### Remove job..."
cat jobs/zeppelin-copy-config.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl delete -f -

# Create rest of environment
echo "##### Creating pods..."
cat deployments/zeppelin.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/spark-master.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/spark-worker.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/nginx-proxy.yaml | sed "s/insights-zeppelin-nginx:latest/insights-zeppelin-nginx:$tag/g" | kubectl create -f -

echo ""
echo "##### Waiting 2 minutes for remaining pods and LoadBalancer to be ready #####"
echo ""
sleep 120

echo "Your testing environment is now ready."
echo "URL is below"
kubectl describe service nginx | grep "LoadBalancer Ingress"
echo ""

exit
