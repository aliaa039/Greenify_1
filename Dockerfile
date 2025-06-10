# ---- Base Stage ----
# Use a slim Python image as a starting point
FROM python:3.10-slim AS base

# Set the working directory
WORKDIR /app

# Prevent Python from writing .pyc files
ENV PYTHONDONTWRITEBYTECODE 1
# Ensure Python output is sent straight to the terminal
ENV PYTHONUNBUFFERED 1


# ---- Builder Stage ----
# This stage installs dependencies, including the large PyTorch library
FROM base AS builder

# Install system dependencies that might be needed for Python packages
RUN apt-get update && apt-get install -y --no-install-recommends gcc build-essential

# Install Python dependencies using the CPU-only version of PyTorch
# This is the most important step for reducing image size
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --index-url https://download.pytorch.org/whl/cpu

# Download the model during the build process instead of at runtime
# This makes your container start faster and more reliably
ARG GOOGLE_DRIVE_ID=1orewvjx91kRCpwH_0Zlhc4HbNz3--ybt
ARG MODEL_PATH=plant_best_model(1).pth
RUN gdown --id ${GOOGLE_DRIVE_ID} -O ${MODEL_PATH}


# ---- Final Production Stage ----
# This is the final, small image that will be deployed
FROM base AS final

# Copy the installed Python packages from the builder stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code and the downloaded model
COPY app.py .
COPY --from=builder /app/plant_best_model(1).pth .

# Expose the port the app runs on
EXPOSE 8000

# Use Gunicorn, a production-ready web server, to run the Flask app
# It's more stable and performant than Flask's built-in development server
CMD ["gunicorn", "--workers", "1", "--threads", "4", "--bind", "0.0.0.0:8000", "app:app"]