#!/bin/sh

export KIK_ROOT=$(cd $(dirname $0); pwd)
# Generate PSK cipher
export KIK_PSK=${KIK_PSK:-`openssl rand -base64 32`}

export KIK_IP=192.168.123.47

export KIK_NODE_NAME=t1


# ------------------------------------------------------------------



# portainer
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# install tools
# https://kubernetes.io/docs/tasks/tools/
curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -x -

curl -LO https://ghproxy.com/https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64
chmod +x kind-linux-amd64
mv kind-linux-amd64 /usr/local/bin/kind

#keadm
mkdir $KIK_ROOT/download
cd $KIK_ROOT/download
KUBEEDGE_VERSION=v1.9.5
curl -LO https://github.com/kubeedge/kubeedge/releases/download/${KUBEEDGE_VERSION}/keadm-${KUBEEDGE_VERSION}-linux-amd64.tar.gz
tar xvf keadm-${KUBEEDGE_VERSION}-linux-amd64.tar.gz
mv keadm-${KUBEEDGE_VERSION}-linux-amd64/keadm/keadm /usr/local/bin/


# https://registry-1.docker.io/
docker run -d --name proxy --restart=always --net=kind \
-e REGISTRY_PROXY_REMOTEURL=https://http://hub-mirror.c.163.com registry:2
docker run -d --name registry --restart=always --net=kind \
-p 5000:5000 registry:2

# create kind cluster.yaml

cd system/kind

kind delete clusters test
kind create cluster \
--config $KIK_ROOT/system/kind/cluster.yaml \
--name test \
--image kindest/node:v1.23.17

cd helm/kubeedge/cloudcore
bash -x install.sh

# get join token
# export KUBEEDGE_TOKEN=$(keadm --kube-config ${HOME}/.kube/config gettoken)
export KUBEEDGE_TOKEN=$(kubectl get secret -nkubeedge tokensecret -o=jsonpath='{.data.tokendata}' | base64 -d)

# edge node join
echo "keadm join --cloudcore-ipport=${KIK_IP}:10000 --edgenode-name=t1 --token=${KUBEEDGE_TOKEN}"

# install edgemesh
helm install edgemesh --namespace kubeedge \
--set agent.psk=${KIK_PSK} \
--set agent.relayNodes[0].nodeName=k8s-master,agent.relayNodes[0].advertiseAddress="{${KIK_IP}}" \
$KIK_ROOT/helm/edgemesh


# install edgemesh gateway
helm install edgemesh-gateway --namespace kubeedge \
--set nodeName=${KIK_NODE_NAME} \
--set psk=${KIK_PSK} \
--set relayNodes[0].nodeName=${KIK_NODE_NAME},relayNodes[0].advertiseAddress="{${KIK_IP}}" \
$KIK_ROOT/helm/edgemesh-gateway


# install edgemesh gateway example
kubectl apply -f ${KIK_ROOT}/build/examples/hostname-lb-random-gateway.yaml

kubectl get gw
