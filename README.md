# 🌐 Microservices Demo – AWS Cloud Edition 🚀

Ein modernes Microservices-Projekt, das in der AWS Cloud mit vollständiger CI/CD-Pipeline läuft.
Basierend auf dem Google microservices-demo – erweitert um:

✅ AWS Infrastruktur (EKS, RDS, ECR)

✅ Terraform Infrastructure as Code

✅ Jenkins CI/CD Pipeline

✅ Automatisierte Deployments in Kubernetes (EKS)

# 🆕 Was wurde geändert?

✔ Cloud-Provider-Wechsel:
Von Google Cloud (GKE) → AWS Cloud (EKS, RDS, ECR)

✔ CI/CD Integration:
Neue Jenkins Pipeline, die:

- Docker-Images baut

- Images in AWS ECR pusht

- Microservices in EKS deployed

✔ Infrastructure as Code:

- Terraform-Scripts erstellen die gesamte AWS-Umgebung:
- VPC, Subnetze, Internet Gateway, EKS-Cluster, Node Groups, - RDS.

# ☁️ Architektur

- graph TD
- A[Developer] -->|Push Code| B[Jenkins CI/CD]
- B -->|Build Docker Images| C[AWS ECR]
- B -->|Deploy to| D[EKS Cluster]
- D -->|Pods| E[Microservices]
- D -->|DB Connection| F[RDS PostgreSQL]

# 📦 Projektstruktur

- microservices-demo/
- ├── docker-compose-alisina/ # Docker-Compose für lokale - - - - Entwicklung
- ├── k8s/ # Kubernetes Manifeste
- ├── protos/ # gRPC Protobuf Dateien
- ├── terraform/ # Terraform-Scripts für AWS
- ├── Jenkinsfile # Jenkins CI/CD Pipeline
- ├── Dockerfile # Root Dockerfile
- └── README.md # Diese Datei

# 🛠 Verwendete Technologien

- Tool/Service Beschreibung
- 🌐 AWS EKS Kubernetes-Cluster in der AWS Cloud
- 📦 Terraform Infrastructure as Code für AWS
- 🤖 Jenkins CI/CD Pipeline
- 🐳 Docker Containerisierung der Microservices
- ☸️ Kubernetes Orchestrierung der Microservices
- 📥 AWS ECR Docker-Image Registry
- 🛢 AWS RDS PostgreSQL-Datenbank

👨‍💻 Autor

- Ali Sina Yozbashi
