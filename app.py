from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello! This is the homepage for our demo API."

@app.route("/api/status")
def api_status():
    return jsonify({
        "status": "Online",
        "message": "The demo API is running!"
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))