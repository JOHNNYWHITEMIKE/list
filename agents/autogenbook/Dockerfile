# Dockerfile for Autogenbook
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY src/ ./src/
COPY config/ ./config/
COPY README.md .

# Install Python dependencies (if requirements.txt exists)
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Default command
CMD ["python", "src/main.py"]
