# docker-proxy-registry-kind
https://maelvls.dev/docker-proxy-registry-kind/
```bash
docker run -d --name proxy --restart=always --net=kind \
-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io registry:2
docker run -d --name registry --restart=always --net=kind \
-p 5000:5000 registry:2
kind create cluster --config /dev/stdin <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
endpoint = ["http://proxy:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
endpoint = ["http://registry:5000"]
EOF
```