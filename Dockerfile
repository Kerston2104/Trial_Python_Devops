# 1. Start with a base Python image (lightweight and fast)
FROM python:3.9-slim

# 2. Set the working directory inside the container
WORKDIR /app
# ^^^^^ This is the path inside the container, not your PC.

# 3. Copy the dependencies file and install them
COPY requirements.txt .
# Use --no-cache-dir for smaller image size
RUN pip install -r requirements.txt

RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-17.04.0-ce.tgz \
  && tar xzvf docker-17.04.0-ce.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker-17.04.0-ce.tgz
# 4. Copy the rest of your app code (app.py)
COPY . .

# 5. Tell Azure that our app internally runs on port 8080
# This matches the WEBSITES_PORT setting in main.tf
ENV PORT=8080

# 6. The command to run the app using a real server (Gunicorn)
# This starts the app on 0.0.0.0 (all interfaces) using the defined PORT
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
