
```bash
HOST1=116.203.62.155 # Nürnberg
HOST2=46.62.253.183 # Helsinki
#HOST3=78.47.242.152 # Falkenstein
SSH_KEY=~/.ssh/id_ed25519
USER=root

k3sup install --host $HOST1 --context k3s-cilium-001 --tls-san $HOST1 --sudo --k3s-extra-args '--flannel-backend=none --disable-kube-proxy --cluster-cidr=10.10.0.0/16 --service-cidr=10.15.0.0/16' --ssh-key $SSH_KEY --user $USER
k3sup install --host $HOST2 --context k3s-cilium-002 --tls-san $HOST2 --sudo --k3s-extra-args '--flannel-backend=none --disable-kube-proxy --cluster-cidr=10.120.0.0/16 --service-cidr=10.125.0.0/16' --ssh-key $SSH_KEY --user $USER --merge
#k3sup install --host $HOST3 --context k3s-cilium-003 --tls-san $HOST3 --sudo --k3s-extra-args '--flannel-backend=none --disable-kube-proxy --cluster-cidr=10.240.0.0/16 --service-cidr=10.245.0.0/16' --ssh-key $SSH_KEY --user $USER --merge

export KUBECONFIG=~/.kube/config:./kubeconfig

CLUSTER1=k3s-cilium-001
CLUSTER2=k3s-cilium-002
#CLUSTER3=k3s-cilium-003

cilium install --values ./k3s-cilium-001.yaml --context $CLUSTER1
cilium install --values ./k3s-cilium-002.yaml --context $CLUSTER2
#cilium install --values ./k3s-cilium-003.yaml --context $CLUSTER3

# wait 2 min

k --context $CLUSTER1 create ns tests
k --context $CLUSTER1 create -f manifests/nuernberg -n tests

k --context $CLUSTER2 create ns tests
k --context $CLUSTER2 create -f manifests/helsinki -n tests

#k --context $CLUSTER3 create ns tests
#k --context $CLUSTER3 create -f manifests/falkenstein

curl -ks https://nuernberg.ciliumdemo.entengott.com | jq '.environment'
curl -ks https://helsinki.ciliumdemo.entengott.com | jq '.environment'
#curl -ks https://falkenstein.ciliumdemo.entengott.com | jq '.environment'

k --context $CLUSTER1 -n tests scale deployment/echo-server-nuernberg --replicas 0

# wait 1-2 min

cilium clustermesh enable --context $CLUSTER1 --service-type NodePort 
cilium clustermesh enable --context $CLUSTER2 --service-type NodePort 
#cilium clustermesh enable --context $CLUSTER3 --service-type NodePort 

cilium clustermesh status --context $CLUSTER2 --wait

cilium clustermesh connect --context $CLUSTER1 --destination-context $CLUSTER2
#cilium clustermesh connect --context $CLUSTER1 --destination-context $CLUSTER3
#cilium clustermesh connect --context $CLUSTER2 --destination-context $CLUSTER3

cilium clustermesh status --context $CLUSTER2 --wait

# Für StatefulServices
#cilium upgrade --reuse-values --set clustermesh.enableEndpointSliceSynchronization=true --context $CLUSTER1
#cilium upgrade --reuse-values --set clustermesh.enableEndpointSliceSynchronization=true --context $CLUSTER2
#cilium upgrade --reuse-values --set clustermesh.enableEndpointSliceSynchronization=true --context $CLUSTER3

k --context $CLUSTER1 delete pod -n kube-system -l app.kubernetes.io/name=cilium-agent
k --context $CLUSTER2 delete pod -n kube-system -l app.kubernetes.io/name=cilium-agent
#k --context $CLUSTER3 delete pod -n kube-system -l app.kubernetes.io/name=cilium-agent

k --context $CLUSTER1 delete pod -n kube-system -l app.kubernetes.io/name=clustermesh-apiserver
k --context $CLUSTER2 delete pod -n kube-system -l app.kubernetes.io/name=clustermesh-apiserver
#k --context $CLUSTER3 delete pod -n kube-system -l app.kubernetes.io/name=clustermesh-apiserver

cilium clustermesh status --context $CLUSTER2 --wait

k --context $CLUSTER1 annotate svc/echo-server service.cilium.io/global=true -n tests
k --context $CLUSTER1 annotate svc/echo-server service.cilium.io/affinity=local -n tests

k --context $CLUSTER2 annotate svc/echo-server service.cilium.io/global=true -n tests
k --context $CLUSTER2 annotate svc/echo-server service.cilium.io/affinity=local -n tests

#k --context $CLUSTER3 annotate svc/echo-server service.cilium.io/global=true -n tests
#k --context $CLUSTER3 annotate svc/echo-server service.cilium.io/affinity=local -n tests

#k --context $CLUSTER3 exec pod/ubuntu -n tests -- apt update
#k --context $CLUSTER3 exec pod/ubuntu -n tests -- apt install dnsutils curl -y
#k --context $CLUSTER1 exec pod/ubuntu -n tests -- apt update
#k --context $CLUSTER1 exec pod/ubuntu -n tests -- apt install dnsutils curl -y

#k --context $CLUSTER2 exec pod/ubuntu -n tests -- apt update
#k --context $CLUSTER2 exec pod/ubuntu -n tests -- apt install dnsutils curl -y

#k --context $CLUSTER1 exec pod/ubuntu -n tests -- nslookup hello-kubernetes-cip
#k --context $CLUSTER1 exec pod/ubuntu -n tests -- nslookup hello-kubernetes-headless

#k --context $CLUSTER3 exec pod/ubuntu -n tests -- curl hello-kubernetes-cip
#k --context $CLUSTER3 exec pod/ubuntu -n tests -- nslookup hello-kubernetes-headless
```

### Links
[[Cilium]]