from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    # A slightly longer and more descriptive homepage response for presentation
    # This page confirms the success of the entire pipeline.
    return "<h1>Project DevOps Success!</h1><p>This is the default endpoint of the Python Flask application, deployed as a containerized service via Jenkins, Terraform, and Azure App Service.</p><p>Check the <a href='/api/status'>/api/status</a> endpoint for the container health.</p>"

@app.route("/api/status")
def api_status():
    return jsonify({
        "status": "Online and Operational",
        "message": "The demo API is fully running and serving requests from an Azure App Service container.",
        "version": "1.0.0",
        "environment": "Production"
    })

if __name__ == "__main__":
    # Use the PORT environment variable provided by Azure App Service, default to 8080 locally
    port = int(os.environ.get('PORT', 8080))
    # Keeping app.run for local testing if needed, Docker CMD overrides this.
    app.run(host='0.0.0.0', port=port)
