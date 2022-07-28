#!/usr/bin/env bash
 
export KUBECONFIG=/Users/stp/Source/CluedIn/Home-Dev/src/env/default/kubeconfig

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/metallb.yaml   

kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

network=$(docker network inspect kind -f "{{(index .IPAM.Config 0).Subnet}}" | cut -d '.' -f1,2)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $network.255.1-$network.255.250
EOF
