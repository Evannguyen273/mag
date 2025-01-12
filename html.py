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
        #user-input {
            width: 100%;
            padding: 10px;
            margin-bottom: 10px;
            box-sizing: border-box;
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
    <input type="text" id="user-input" placeholder="Type your message...">

    <script>
        (async function() {
            const chatBox = document.getElementById('chat-box');
            const userInput = document.getElementById('user-input');

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

            // Handle WebSocket connection
            ws.onopen = () => console.log('Connected');
            ws.onmessage = (event) => {
                addMessage(event.data, false);
            };

            // Handle user input
            userInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter' && userInput.value.trim()) {
                    const message = userInput.value;
                    addMessage(message, true);
                    ws.send(message);
                    userInput.value = '';
                }
            });
        })();
    </script>
</body>
</html>
