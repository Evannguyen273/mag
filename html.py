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
    </style>
</head>
<body>
    <div id="chat-box"></div>
    <div class="input-container">
        <input type="text" id="user-input" placeholder="Type your message...">
        <button id="send-button">Send</button>
    </div>

    <script>
        (async function() {
            const chatBox = document.getElementById('chat-box');
            const userInput = document.getElementById('user-input');
            const sendButton = document.getElementById('send-button');

            // Connect to Web PubSub
            const response = await fetch('/negotiate');
            const data = await response.json();
            const ws = new WebSocket(data.url);

            // Add message to chat box
            function addMessage(text, isUser) {
                const messageDiv = document.createElement('div');
                messageDiv.className = `message ${isUser ? 'user-message' : 'ai-message'}`;
                messageDiv.textContent = text;
                chatBox.appendChild(messageDiv);
                chatBox.scrollTop = chatBox.scrollHeight;
            }

            // Function to send message
            function sendMessage() {
                const message = userInput.value.trim();
                if (message) {
                    addMessage(message, true);
                    ws.send(message);
                    userInput.value = '';
                }
            }

            // Handle WebSocket connection
            ws.onopen = () => console.log('Connected');
            ws.onmessage = (event) => {
                addMessage(event.data, false);
            };

            // Handle button click
            sendButton.addEventListener('click', sendMessage);

            // Handle Enter key
            userInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    sendMessage();
                }
            });
        })();
    </script>
</body>
</html>
