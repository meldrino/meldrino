const WebSocket = require('ws');
const { execSync } = require('child_process');
const ws = new WebSocket('wss://api.zebedee.io/api/internal/v1/qrauth-socket');
ws.on('open', () => {
  ws.send(JSON.stringify({type:'internal-connection-sub-qr-auth',data:{browserOS:'Android',browserName:'Chrome',QRCodeZClient:'browser-extension'}}));
});
ws.on('message', async (data) => {
  const msg = JSON.parse(data.toString());
  console.log(new Date().toISOString(), 'Received:', data.toString());
  if (msg.type === 'internal-hash-retrieved') {
    const hash = encodeURIComponent(msg.data);
    setTimeout(() => {
      try {
        execSync('C:\\Users\\Andy\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe shell am start -a android.intent.action.VIEW -d "https://zebedee.io/qrauth/' + hash + '?QRCodeZClient=browser-extension"');
        console.log('Intent fired!');
      } catch(e) { console.log('Intent error:', e.message); }
    }, 3000);
  }
  if (msg.type === 'QR_CODE_AUTH_USER_ACCEPT') {
    console.log('*** GOT TOKEN ***', msg.data.token);
    ws.close();
    process.exit();
  }
  if (msg.type === 'QR_CODE_AUTH_USER_DATA') {
    console.log('*** USER DATA ***', data.toString());
  }
});
ws.on('close', () => {
  console.log('WebSocket closed');
});
process.stdin.resume();
