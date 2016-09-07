#!/bin/bash

echo "Creating Elasticsearch services..."
kubectl create namespace es-cluster
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml

kubectl create -f es-master.yaml --validate=false
while true; do
    active=`kubectl get deployments --namespace=es-cluster | grep es-master | awk '{print $5}'`
    if [ "$active" == "1" ]; then
	break
    fi
    sleep 2
done 

kubectl create -f es-client.yaml --validate=false
while true; do
    active=`kubectl get deployments --namespace=es-cluster | grep es-client | awk '{print $5}'`
    if [ "$active" == "1" ]; then
	break
    fi
    sleep 2
done

kubectl create -f es-data.yaml --validate=false
while true; do
    active=`kubectl get deployments --namespace=es-cluster | grep es-data | awk '{print $5}'`
    if [ "$active" == "1" ]; then
	break
    fi
    sleep 2
done 

# Scale the cluster to 3 master, 4 data, and 2 client nodes
echo "Scaling cluster..."
kubectl scale deployment es-master --namespace=es-cluster --replicas 3 
kubectl scale deployment es-client  --namespace=es-cluster --replicas 2
kubectl scale deployment es-data  --namespace=es-cluster --replicas 4

echo "Waiting for Elasticsearch public service IP..."
while true; do
    es_ip=`kubectl get svc elasticsearch --namespace=es-cluster | grep elasticsearch | awk '{print $3}'`
    if [ "$es_ip" != "<pending>" ]; then
	break
    fi
    sleep 2
done    
echo "Elasticsearch public IP:    "$es_ip

