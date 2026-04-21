#Uses a lightweight Python 3.10 OS image  
FROM python:3.10-slim-bullseye

#install necessary dependencies for the application
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*
#Set the working directory in the container to /app
WORKDIR /app
#Copy the requirements.txt file to the working directory and install the required Python packages using pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
#Copy the entire application code from the host machine to the working directory in the container
COPY . .
#Opens port 8000   
EXPOSE 8000
#Runs FastAPI sever using Uvicorn
CMD uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}