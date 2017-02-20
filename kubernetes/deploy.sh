#!/bin/bash

echo ""
echo "We're going to set up your testing environment. Enter to accept (defaults)"
echo ""
echo "What's the tag of the docker image you built? (latest)"
read tag
echo ""

# Set defaults if no input
if [[ -z "$tag" ]]; then
  branch="latest"
  fi

# debug
echo $tag
sleep 120

# Allow case insensitive matching
shopt -s nocasematch

# Set branches to use for each app, exit if invalid
# if [[ $app == 'Site' ]]; then
#   if [[ ! -z "$branch" ]]; then
#     atlas_branch="latest"
#     directory_branch="latest"
#     site_branch="$branch"
#     widget_branch="latest"
#   else echo "Oops, invalid input, try again..." \
#     && exit
#   fi
# elif [[ $app == "Directory" ]]; then
#   if [[ ! -z "$branch" ]]; then
#     atlas_branch="latest"
#     directory_branch=$branch
#     site_branch="latest"
#     widget_branch="latest"
#   else echo "Oops, invalid input, try again..." \
#     && exit
#   fi
# elif [[ $app == "Atlas" ]]; then
#   if [[ ! -z "$branch" ]]; then
#     atlas_branch=$branch
#     directory_branch="latest"
#     site_branch="latest"
#     widget_branch="latest"
#   else echo "Oops, invalid input, try again..." \
#     && exit
#   fi
# elif [[ $app == "Widget" ]]; then
#   if [[ ! -z "$branch" ]]; then
#     atlas_branch="latest"
#     directory_branch="latest"
#     site_branch="latest"
#     widget_branch=$branch
#   else echo "Oops, invalid input, try again..." \
#     && exit
#   fi
# else echo "Oops, invalid input, try again..." \
#   && exit
# fi

# Return case matching to normal
shopt -u nocasematch

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

# echo ""
# echo "#####   This will take about 10 minutes. Ping Pong?    #####"
# echo ""
# echo "ICAgICAgICAgIE8gLgogICAgICAgIF8vfFxfLU8KICAgICAgIF9fX3xfX19fX19f
# CiAgICAgIC8gICAgIHwgICAgIFwKICAgICAvICAgICAgfCAgICAgIFwKICAgICMj
# IyMjIyMjIyMjIyMjIyMjCiAgIC8gICBfICggKXwgICAgICAgIFwKICAvICAgKCAp
# IHwgfCAgICAgICAgIFwKIC8gIFwgIHxfLyAgfCAgICAgICAgICBcCi9fX19fXC98
# X19fX3xfX19fX19fX19fX1wKICAgfCAgIHwgICAgICAgICAgICAgfAogICB8ICAv
# IFwgICAgICAgICAgICB8CiAgIHwgLyAgIFwgICAgICAgICAgIHwKICAgXy8gICAg
# L18K" | base64 --decode
# echo ""

sleep 5

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

# Create configmaps
# echo "##### ConfigMaps..."
# kubectl create -f configmaps/atlas.yaml
# cat configmaps/site.yaml | sed "s/branch.staging/$branch.staging/g" | kubectl create -f -
# cat configmaps/widget.yaml | sed "s/branch.staging/$branch.staging/g" | kubectl create -f -

# Create secrets
echo "##### Secrets..."
kubectl create -f secrets/dockerhub.yaml
kubectl create -f secrets/zeppelin-deploy-secrets.yaml

# Create persistent volume claim
echo "##### Storage..."
kubectl create -f storage/aws-ebs.yaml
kubectl create -f storage/zeppelin-pvc.yaml

# Create dependencies
# kubectl create -f deployments/dependencies.yaml
# echo ""
# echo "##### Waiting 2 minutes for pods to be ready #####"
# echo ""
# sleep 120

# Run db:setup
cat jobs/zeppelin-copy-config.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
# echo ""
# echo "##### Waiting 5 minutes for db:setup to complete #####"
# echo ""
# sleep 300

# Delete job
cat jobs/zeppelin-copy-config.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl delete -f -

# Create rest of environment
cat deployments/zeppelin.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/spark-master.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/spark-worker.yaml | sed "s/insights-zeppelin-spark:latest/insights-zeppelin-spark:$tag/g" | kubectl create -f -
cat deployments/nginx-proxy.yaml | sed "s/insights-zeppelin-nginx:latest/insights-zeppelin-nginx:$tag/g" | kubectl create -f -

echo ""
echo "##### Waiting 3 minutes for remaining pods to be ready #####"
echo ""
sleep 180

echo "Your testing environment is now ready."
echo "URL is below"
kubectl describe service nginx
echo ""

exit
