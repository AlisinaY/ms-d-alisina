#!/bin/bash
set -eux

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=${AWS_REGION:-"eu-central-1"}
export CLUSTER_NAME=${CLUSTER_NAME:-"msdemo-dev-eks"}
export KUBECONFIG=${KUBECONFIG:-"./kubeconfig"}
export HELM_RELEASE=${HELM_RELEASE:-"microservices-demo"}
export NAMESPACE=${NAMESPACE:-"microservices-demo"}

# kubectl installieren 
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi

# helm installieren 
if ! command -v helm >/dev/null 2>&1; then
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# kubeconfig konfigurieren
aws eks update-kubeconfig \
    --region $AWS_DEFAULT_REGION \
    --name $CLUSTER_NAME \
    --alias $CLUSTER_NAME \
    --kubeconfig $KUBECONFIG

# Verbindung prüfen
kubectl --kubeconfig=$KUBECONFIG get nodes

# External Secrets Operator installieren
helm repo add external-secrets https://charts.external-secrets.io
helm repo update 
helm install external-secrets external-secrets/external-secrets \
    -n external-secrets --create-namespace

# Auf Webhook warten
echo "⏳ Warte auf Webhook Deployment..."
kubectl rollout status deployment external-secrets-webhook -n external-secrets --timeout=120s

# ServiceAccount, ClusterSecretStore, ExternalSecret anwenden
kubectl apply -f ./charts/external-secrets/templates/serviceaccount.yaml
kubectl apply -f ./charts/external-secrets/templates/ClusterSecretStore.yaml

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f ./charts/external-secrets/templates/externalsecret.yaml -n $NAMESPACE

# Microservices Helm Chart deployen
helm upgrade --install $HELM_RELEASE ./charts/external-secrets \
    --namespace $NAMESPACE \
    --create-namespace \
    --kubeconfig $KUBECONFIG

