#!/bin/bash

# Authenticate with the cluster 
az aks get-credentials --resource-group $ARGO_RESOURCE_GROUP --name $ARGO_AKS_CLUSTER_NAME --admin

# Kubectl
kubectl apply -f kubernetes/configmaps.yml
kubectl apply -f kubernetes/secrets.yml
kubectl apply -f kubernetes/deployments.yml
kubectl apply -f kubernetes/services.yml
kubectl apply -f kubernetes/ingresses.yml
