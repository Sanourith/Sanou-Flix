sanou-flix/
├── apps/
│   ├── backend/          # FastAPI + scanner
│   │   ├── scripts/
│   │   │   └── 1_scan_media.py
│   │   └── app.py
│   ├── frontend/         # Next.js
│   └── nginx/            # reverse proxy + media
│       └── nginx.conf
│
├── data/
│   ├── raw/              # CSV bruts
│   └── processed/        # CSV nettoyés
│
├── infra/
│   ├── modules/
│   │   ├── docker_host/      # installe Docker
│   │   ├── compose/          # génère docker-compose.yml
│   │   ├── database/         # PostgreSQL container
│   │   ├── media_mount/      # monte ton HDD
│   │   └── scanner/          # job Python
│   │
│   ├── environments/
│   │   └── local/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── outputs.tf
│   │
│   ├── provider.tf
│   ├── backend.tf (local)
│   └── versions.tf
│
├── docker-compose.yml       # généré ou versionné
├── .env                     # DB_PASSWORD, etc.
├── docs/
│   └── architecture.md
├── scripts/
│   ├── setup.sh             # init + docker + terraform init
│   ├── up.sh                # docker compose up
│   └── down.sh
└── README.md
