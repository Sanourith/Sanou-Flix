FROM python:3.12-slim

LABEL maintainer="Sanou-Flix Scanner"
LABEL description="Job one-shot : scan SSD + import CSV → PostgreSQL"

WORKDIR /app

# Dépendances système minimales
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Dépendances Python
COPY requirements.scanner.txt .
RUN pip install --no-cache-dir -r requirements.scanner.txt

# Code source
COPY . .

CMD ["python", "scripts/1_scan_media.py"]
