# Use a lightweight Python image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory inside the container
WORKDIR /app

# Install system dependencies required for image processing
RUN apt-get update && apt-get install -y \
    gcc \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (to cache dependencies)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy application code and model
COPY . .

# Expose Flask's port
EXPOSE 3000

# Use gunicorn for production (with 1 worker to reduce RAM usage)
RUN pip install gunicorn
CMD ["gunicorn", "--workers=1", "--bind=0.0.0.0:3000", "app:app"]
