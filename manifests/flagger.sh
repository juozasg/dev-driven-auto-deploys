kind create cluster --config kind-config.yaml


helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
kubectl create ns ingress-nginx
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.hostPort.enabled=true \
    --set controller.service.type=NodePort \
    --set controller.metrics.enabled=true \
    --set controller.podAnnotations."prometheus\.io/scrape"=true \
    --set controller.podAnnotations."prometheus\.io/port"=10254


#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# k apply -f kind-ingress-nginx-deploy.yaml

# install podinfo
k apply -k flagger-podinfo

# install flagger
helm repo add flagger https://flagger.app
helm upgrade -i flagger flagger/flagger \
    --namespace ingress-nginx \
    --set prometheus.install=true \
    --set meshProvider=nginx


# install load test
helm upgrade -i flagger-loadtester flagger/loadtester

# canary and patch ingress
k apply -f canary.yaml
k apply -f ingress.yaml

# bump version
k delete canary/podinfo
k apply -f canary.yaml
k set image deployment/podinfo \
    podinfod=ghcr.io/stefanprodan/podinfo:6.0.4

k delete canary/podinfo
k apply -f canary.yaml

# events
kubectl describe canary/podinfo

kubectl logs deploy/flagger -n ingress-nginx -f | jq .msg

