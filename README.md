# 🎬 Sanou-Flix - Private Streaming Platform

A personal project for building a private streaming platform to host and watch my own movies, series, and anime.

---

## 📋 Overview

This application allows me to:
- Store all my media in a centralized system
- Automatically catalog metadata (title, genre, duration, etc.)
- Browse through an intuitive web interface
- Stream videos directly from the browser
- Manage my personal collection

---

## 🏗️ Architecture

### 🧩 Tech Stack
- **Infrastructure**: Local Kubernetes (Minikube) + Terraform
- **Database**: PostgreSQL (metadata)
- **Storage**: MinIO (video files)
- **Backend**: FastAPI (Python)
- **Frontend**: React
- **Streaming**: HLS/DASH

### ⚙️ Kubernetes Components
- Dedicated namespace for the application
- Persistent Volumes for data and media storage
- Services exposed via NodePort/Ingress
- ConfigMaps for configuration management

---

## 🚀 Quick Start

### 🧰 Prerequisites
- Terraform >= 1.5
- Docker Desktop
- kubectl
- At least 8GB of available RAM
- 50GB+ of disk space

### 🏗️ Installation

1. **Clone the repository**
```bash
git clone <your-repo>
cd netflix-perso
Deploy the infrastructure
```

```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
Configure kubectl

eval $(minikube docker-env)
kubectl config use-context minikube
```
```bash

eval $(minikube docker-env)
kubectl config use-context minikube
```

Verify the deployment

```bash
kubectl get pods -n netflix
kubectl get services -n netflix
```
📁 Project Structure
```
netflix-perso/
├── infrastructure/       # IaC with Terraform
├── kubernetes/           # Kubernetes manifests
├── backend/              # Python/FastAPI API
├── frontend/             # React interface
├── scripts/              # Utility scripts
└── docs/                 # Documentation
```
🛠️ Development
🧩 Current Phase: Infrastructure ✅
 Architecture defined

 Terraform Minikube setup

 Kubernetes namespaces

 PostgreSQL deployment

 MinIO deployment

🚧 Next Phases
 Backend API (CRUD for media)

 Frontend interface

 Video upload and playback

 Automatic transcoding

 Search and filtering

📝 Notes
⚠️ Known Limitations
Local only: No external access yet

Performance: Depends on local machine resources

Storage: Limited by your local disk capacity

🌱 Future Improvements
Migration to a cloud cluster (AWS EKS, GCP GKE)

Automatic video transcoding

Multi-language subtitles

Recommendations based on watch history

Mobile application