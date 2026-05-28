FROM python:3.12-slim

LABEL maintainer="Sanou-Flix API"
LABEL description="API REST FastAPI + streaming vidéo"

WORKDIR /app

# Dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code source
COPY . .

# Uvicorn en mode reload pour le dev
# En prod : retirer --reload et ajouter --workers 4
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
