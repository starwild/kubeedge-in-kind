kubectl create ns kubeedge

\ls crds/*.yaml | xargs -I{} kubectl apply -f {}

sh -c "helm upgrade --install cloudcore . --namespace kubeedge --create-namespace -f ./values.yaml --set cloudCore.modules.cloudHub.advertiseAddress[0]=192.168.123.47"

