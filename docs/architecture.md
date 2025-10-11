```
Sanou-Flix/
├── README.md
├── .gitignore
├── docs/
│   └── architecture.md
├── infrastructure/
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── modules/
│           ├── minikube/
│           └── kubernetes/
├── kubernetes/
│   ├── base/
│   │   ├── namespace.yaml
│   │   └── storage-class.yaml
│   ├── database/
│   │   ├── postgres-deployment.yaml
│   │   ├── postgres-service.yaml
│   │   └── postgres-pvc.yaml
│   ├── storage/
│   │   ├── minio-deployment.yaml
│   │   └── minio-service.yaml
│   ├── backend/
│   │   ├── api-deployment.yaml
│   │   └── api-service.yaml
│   └── frontend/
│       ├── web-deployment.yaml
│       └── web-service.yaml
├── backend/
│   └── (ton code API plus tard)
├── frontend/
│   └── (ton code web plus tard)
└── scripts/
├── setup.sh
└── teardown.sh
```