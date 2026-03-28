# Use a slim Python image for a smaller footprint
FROM python:3.10-bullseye

# Install system dependencies for OpenCV and YOLO
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port Railway uses
EXPOSE 8000

# Start the application using uvicorn
# We use the $PORT variable which Railway provides automatically
CMD uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}