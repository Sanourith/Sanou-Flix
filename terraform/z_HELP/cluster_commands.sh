#! /bin/bash

# in case of ~/.kube/config problem
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
mkdir -p ~/.kube
docker exec k3s-cluster-server-0 cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config-k3s
sed -i 's/https:\/\/127.0.0.1:6443/https:\/\/localhost:6443/g' ~/.kube/config-k3s
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes -o wide
