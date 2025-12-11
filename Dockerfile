## Parent image
FROM python:3.10-slim

## Essential environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

## Work directory inside the docker container
WORKDIR /app

## Installing system dependencies (including build tools for orjson)
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

## Copy requirements first for better caching
COPY requirements.txt setup.py ./

## Install Python dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -e .

## Copy application code
COPY . .

## Create results directory
RUN mkdir -p results

## Expose port
EXPOSE 8501

## Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

## Run the app
CMD ["streamlit", "run", "application.py", "--server.port=8501", "--server.address=0.0.0.0", "--server.headless=true"]