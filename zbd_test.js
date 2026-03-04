const WebSocket = require('ws');

const ws = new WebSocket('wss://api.zebedee.io/api/internal/v1/qrauth-socket');

ws.on('open', () => {
  console.log('Connected!');
  ws.send(JSON.stringify({
    type: 'internal-connection-sub-qr-auth',
    data: {
      browserOS: 'Android',
      browserName: 'Chrome',
      QRCodeZClient: 'browser-extension'
    }
  }));
});

ws.on('message', (data) => {
  console.log('Received:', data.toString());
});

ws.on('error', (err) => {
  console.log('Error:', err.message);
});

ws.on('close', (code, reason) => {
  console.log('Connection closed:', code, reason.toString());
});

process.stdin.resume();
console.log('Waiting... press Ctrl+C to exit');
