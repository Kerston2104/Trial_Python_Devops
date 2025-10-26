# 1. Start with a base Python image
FROM python:3.9-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy the dependencies file and install them
COPY requirements.txt .
RUN pip install -r requirements.txt

# 4. Copy the rest of your app code
COPY . .

# 5. Tell Azure that our app runs on port 8080
ENV PORT=8080

# 6. The command to run the app using a real server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]