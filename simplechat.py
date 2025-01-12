# server.py
import os
from flask import Flask, request, send_from_directory, Response
from azure.messaging.webpubsubservice import WebPubSubServiceClient
import json

app = Flask(__name__)

# Simple configuration
connection_string = os.environ.get('WebPubSubConnectionString')
service = WebPubSubServiceClient.from_connection_string(connection_string, hub='SimpleChat')

def run_chat(prompt):
    # Your existing AI chat function
    print(f"Processing message: {prompt}")  # Debug print
    return "AI Response to: " + prompt

@app.route('/')
def home():
    print("Serving index.html")  # Debug print
    return send_from_directory('.', 'index.html')

@app.route('/negotiate')
def negotiate():
    print("Negotiating connection")  # Debug print
    token = service.get_client_access_token()
    print(f"Token URL: {token['url']}")  # Debug print
    return {'url': token['url']}, 200

@app.route('/eventhandler', methods=['POST', 'OPTIONS'])
def handle_event():
    if request.method == 'OPTIONS':
        res = Response()
        res.headers['WebHook-Allowed-Origin'] = '*'
        return res
    
    print("Received event:", request.headers.get('ce-type'))  # Debug print
    print("Request data:", request.data)  # Debug print
    
    event_type = request.headers.get('ce-type')
    
    if event_type == 'azure.webpubsub.user.message':
        try:
            # Get user message and generate AI response
            user_message = request.data.decode('UTF-8')
            print(f"Received message: {user_message}")  # Debug print
            
            ai_response = run_chat(user_message)
            print(f"Sending response: {ai_response}")  # Debug print
            
            # Send back the AI response
            service.send_to_all(json.dumps({
                'message': ai_response,
                'isAi': True
            }))
            return '', 204
        except Exception as e:
            print(f"Error processing message: {str(e)}")  # Debug print
            return str(e), 500
        
    return '', 200

if __name__ == '__main__':
    print("Starting server on port 8080")  # Debug print
    app.run(port=8080, debug=True)
