FROM python:3.11-slim

WORKDIR /app

# Copy application files
COPY src/ ./src/
COPY config/ ./config/
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run the agent
CMD ["python", "src/main.py"]
