<!DOCTYPE html>
<html>
<head>
    <title>Simple AI Chat</title>
    <style>
        body {
            max-width: 600px;
            margin: 20px auto;
            padding: 20px;
            font-family: Arial, sans-serif;
        }
        #chat-box {
            border: 1px solid #ccc;
            padding: 20px;
            height: 300px;
            overflow-y: auto;
            margin-bottom: 20px;
        }
        .input-container {
            display: flex;
            gap: 10px;
        }
        #user-input {
            flex-grow: 1;
            padding: 10px;
            box-sizing: border-box;
        }
        #send-button {
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        #send-button:hover {
            background-color: #45a049;
        }
        .message {
            margin: 10px 0;
            padding: 10px;
            border-radius: 4px;
        }
        .user-message {
            background-color: #e3f2fd;
        }
        .ai-message {
            background-color: #f5f5f5;
        }
        #status {
            color: #666;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div id="status">Connecting...</div>
    <div id="chat-box"></div>
    <div class="input-container">
        <input type="text" id="user-input" placeholder="Type your message..." disabled>
        <button id="send-button" disabled>Send</button>
    </div>

    <script>
        (async function() {
            const chatBox = document.getElementById('chat-box');
            const userInput = document.getElementById('user-input');
            const sendButton = document.getElementById('send-button');
            const statusDiv = document.getElementById('status');
            let webSocket;

            // Add message to chat box
            function addMessage(text, isUser) {
                console.log('Adding message:', text, 'isUser:', isUser);  // Debug log
                const messageDiv = document.createElement('div');
                messageDiv.className = `message ${isUser ? 'user-message' : 'ai-message'}`;
                messageDiv.textContent = text;
                chatBox.appendChild(messageDiv);
                chatBox.scrollTop = chatBox.scrollHeight;
            }

            // Function to send message
            function sendMessage() {
                const message = userInput.value.trim();
                if (message && webSocket && webSocket.readyState === WebSocket.OPEN) {
                    console.log('Sending message:', message);  // Debug log
                    addMessage(message, true);
                    webSocket.send(message);
                    userInput.value = '';
                } else {
                    console.log('Cannot send message:', {
                        message: message,
                        webSocket: webSocket ? true : false,
                        readyState: webSocket ? webSocket.readyState : 'no socket'
                    });  // Debug log
                }
            }

            try {
                // Connect to Web PubSub
                console.log('Fetching negotiate endpoint');  // Debug log
                const response = await fetch('/negotiate');
                const data = await response.json();
                console.log('Got WebSocket URL:', data.url);  // Debug log

                webSocket = new WebSocket(data.url);

                // Handle WebSocket connection
                webSocket.onopen = () => {
                    console.log('WebSocket connected');  // Debug log
                    statusDiv.textContent = 'Connected';
                    userInput.disabled = false;
                    sendButton.disabled = false;
                };

                webSocket.onclose = () => {
                    console.log('WebSocket disconnected');  // Debug log
                    statusDiv.textContent = 'Disconnected';
                    userInput.disabled = true;
                    sendButton.disabled = true;
                };

                webSocket.onerror = (error) => {
                    console.error('WebSocket error:', error);  // Debug log
                    statusDiv.textContent = 'Error: ' + error;
                };

                webSocket.onmessage = (event) => {
                    console.log('Received message:', event.data);  // Debug log
                    try {
                        const data = JSON.parse(event.data);
                        addMessage(data.message, !data.isAi);
                    } catch (e) {
                        addMessage(event.data, false);
                    }
                };

                // Handle button click
                sendButton.addEventListener('click', sendMessage);

                // Handle Enter key
                userInput.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') {
                        sendMessage();
                    }
                });

            } catch (error) {
                console.error('Setup error:', error);  // Debug log
                statusDiv.textContent = 'Error: ' + error.message;
            }
        })();
    </script>
</body>
</html>
