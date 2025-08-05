pipeline {
    agent {
        docker {
            image "node:18-bullseye"
            args '''
                --user root
                -v /var/run/docker.sock:/var/run/docker.sock
            '''.trim()
        }
    }

    environment {
        AWS_REGION    = "eu-central-1"
        ECR_REGISTRY  = "610351333224.dkr.ecr.${AWS_REGION}.amazonaws.com"
        CARTSERVICE   = "cartservice"
    }

    stages {

        // ============================
        // 1️⃣ Login to AWS-ECR
        // ============================
        stage("Login to ECR") {
            steps {
                sh '''
                    set -eux
                    apt-get update
                    apt-get install -y --no-install-recommends \
                        unzip \
                        docker.io \
                        bash
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip -o awscliv2.zip
                    ./aws/install 
                    rm -rf /var/lib/apt/lists/*
                '''
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION \
                            | docker login --username AWS --password-stdin $ECR_REGISTRY
                    '''
                }
            }
        }

        // ============================
        // 2️⃣ CartService: Tests & Build
        // ============================
        stage("CartService: Run Tests & Build") {
            steps {
                dir("src/cartservice/src") {
                    script {
                        echo "Tests ausführen für CartService..."
                        docker.image('mcr.microsoft.com/dotnet/sdk:9.0').inside {
                            sh '''
                                dotnet restore
                                dotnet test --no-build --configuration Release
                            '''
                        }
                        echo "Tests erfolgreich. Baue Docker Image für CartService..."
                        def imageTag = "${ECR_REGISTRY}/${CARTSERVICE}:latest"
                        sh """
                            echo "Baue Docker Image für ${CARTSERVICE}"
                            docker build -t ${imageTag} .
                            docker push ${imageTag}
                        """
                    }
                }
            }
        }

        // ============================
        // 3️⃣ Build & Push Docker Images
        // ============================
        stage("Build & Push Docker Images") {
            steps {
                script {
                    def services = [
                        "adservice",
                        "checkoutservice",
                        "currencyservice",
                        "emailservice",
                        "frontend",
                        "loadgenerator",
                        "paymentservice",
                        "productcatalogservice",
                        "recommendationservice",
                        "shippingservice",
                        "shoppingassistantservice"
                    ]

                    for (svc in services) {
                        dir("src/${svc}") {
                            def imageTag = "${ECR_REGISTRY}/${svc}:latest"
                            sh """
                                echo "Building Docker Image for ${svc}"
                                docker build -t ${imageTag} .
                                docker push ${imageTag}
                            """
                        }
                    }
                }
            }
        }

        // ============================
        // 4️⃣ Deploy to EKS with Helm
        // ============================
        stage("Deploy to EKS with Helm") {
            environment {
                CLUSTER_NAME = "msdemo-dev-eks"
                KUBECONFIG   = "${WORKSPACE}/kubeconfig"
                HELM_RELEASE = "microservices-demo"
                NAMESPACE    = "microservices-demo"
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        set -eux

                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        # Install kubectl if not present
                        if ! command -v kubectl >/dev/null 2>&1; then
                        echo "Installing kubectl..."
                        curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl /usr/local/bin/
                        fi

                        # Install helm if not present
                        if ! command -v helm >/dev/null 2>&1; then
                            curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
                        fi

                        # Configure kubeconfig
                        aws eks update-kubeconfig \
                            --region $AWS_DEFAULT_REGION \
                            --name $CLUSTER_NAME \
                            --alias $CLUSTER_NAME \
                            --kubeconfig $KUBECONFIG

                        # Test connection
                        kubectl --kubeconfig=$KUBECONFIG get nodes

                        # Install CRDs first
                    
                       # 1. Add Helm repo + install External Secrets Operator
                       helm repo add external-secrets https://charts.external-secrets.io
                       helm repo update 
                       helm install external-secrets external-secrets/external-secrets \
                       -n external-secrets --create-namespace

                       # 2. Warten, bis der Webhook bereit ist
                       echo "⏳ Warte auf Webhook Deployment..."
                       kubectl rollout status deployment external-secrets-webhook -n external-secrets --timeout=120s

                       # 3. ServiceAccount & ClusterSecretStore anwenden
                       kubectl apply -f ./charts/external-secrets/templates/serviceaccount.yaml
                       kubectl apply -f ./charts/external-secrets/templates/ClusterSecretStore.yaml

                       # 4. ExternalSecret anlegen
                       kubectl create namespace microservices-demo --dry-run=client -o yaml | kubectl apply -f -
                       kubectl apply -f ./charts/external-secrets/templates/externalsecret.yaml -n microservices-demo

                       # 5. Helm Chart 
                       helm upgrade --install $HELM_RELEASE ./charts/external-secrets \
                       --namespace $NAMESPACE \
                       --create-namespace \
                       --kubeconfig $KUBECONFIG

                    '''
                }
            }
        }
    }
}
