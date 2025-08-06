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
if ! helm repo list | grep -q '^external-secrets'; then
    echo "Helm Repo 'external-secrets' wird hinzugefügt..."
    helm repo add external-secrets https://charts.external-secrets.io
else 
    echo "Helm Repo 'external-secrets' ist bereits vorhanden."
fi

helm repo update

# Helm Release nur installieren, wenn noch nicht vorhanden
if ! helm list -n external-secrets | grep -q '^external-secrets'; then 
    echo "Installiere Helm Release 'external-secrets'..."
    helm install external-secrets external-secrets/external-secrets \
         -n external-secrets --create-namespace
else 
    echo "Helm Release 'external-secrets' ist bereits installiert." 
fi            

# Auf Webhook warten
echo "⏳ Warte auf Webhook Deployment..."
kubectl rollout status deployment external-secrets-webhook -n external-secrets --timeout=120s

# Namespace erstellen wenn nicht vorhanden
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Erstellen NameSpace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
else
    echo "Namespace '$NAMESPACE' existiert bereits."
fi 

if ! kubectl get serviceaccount external-secrets-sa -n external-secrets >/dev/null 2>&1; then
     echo "Erstelle Serviceaccount..."

     kubectl apply -f ./charts/external-secrets/templates/serviceaccount.yaml
else 
    echo "Serviceaccont existiert schon."
fi

if ! kubectl get clustersecretstore aws-secrets-store >/dev/null 2>&1; then
    echo "➡️ Erstelle ClusterSecretStore..."
    kubectl create -f ./charts/external-secrets/templates/ClusterSecretStore.yaml
else
    echo "✅ ClusterSecretStore 'aws-secrets-store' existiert bereits."
fi


if ! kubectl get externalsecret my-secret -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "➡️ Erstelle ExternalSecret..."
    kubectl create -f ./charts/external-secrets/templates/externalsecret.yaml -n "$NAMESPACE"
else
    echo "✅ ExternalSecret existiert bereits."
fi



if ! helm status "$HELM_RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "🚀 Installiere Helm-Release '$HELM_RELEASE'..."
    helm install "$HELM_RELEASE" ./charts/external-secrets \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --kubeconfig "$KUBECONFIG"
else
    echo "✅ Helm-Release '$HELM_RELEASE' existiert bereits. Nichts zu tun."
fi
