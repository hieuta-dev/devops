
const http = require('http');
const os = require('os');

const port = Number(process.env.PORT || 8080);
const hostname = os.hostname();
const startTime = Date.now();

const server = http.createServer((req, res) => {

  // Health check for AWS ALB
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, {
      'Content-Type': 'application/json'
    });
    res.end(JSON.stringify({
      status: 'healthy'
    }));
    return;
  }

  // Application information API
  if (req.method === 'GET' && req.url === '/api/status') {
    res.writeHead(200, {
      'Content-Type': 'application/json'
    });

    res.end(JSON.stringify({
      status: 'healthy',
      hostname,
      port,
      uptime: Math.floor(process.uptime()),
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // Web Dashboard
  if (req.method === 'GET' && req.url === '/') {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8'
    });

    res.end(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0">
  <title>DevOps Dashboard</title>
  <style>
    * { box-sizing: border-box; }

    body {
      margin: 0;
      background: #0b1220;
      color: #f8fafc;
      font-family: system-ui, Arial, sans-serif;
    }

    .container {
      max-width: 920px;
      margin: auto;
      padding: 35px 20px;
    }

    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid #334155;
      padding-bottom: 22px;
    }

    h1 { margin-top: 45px; }
    p { color: #94a3b8; }

    .badge {
      background: #14532d;
      color: #86efac;
      padding: 8px 15px;
      border-radius: 20px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      margin-top: 30px;
    }

    .card {
      background: #172338;
      padding: 25px;
      border-radius: 12px;
      border: 1px solid #263449;
    }

    .label {
      color: #94a3b8;
      font-size: 14px;
    }

    .value {
      font-size: 23px;
      font-weight: bold;
      margin-top: 12px;
      overflow-wrap: anywhere;
    }

    .green { color: #4ade80; }
    .blue { color: #60a5fa; }

    button {
      background: #2563eb;
      color: white;
      border: none;
      padding: 12px 20px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 14px;
    }

    button:hover { background: #1d4ed8; }

    .footer {
      margin-top: 40px;
      text-align: center;
      font-size: 13px;
      color: #64748b;
    }

    @media(max-width: 600px) {
      .grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div>
        <strong>🚀 Sample App</strong>
        <p>Fundamentals of DevOps</p>
      </div>
      <span class="badge" id="badge">Live</span>
    </header>

    <h1>Server Dashboard</h1>
    <p>Node.js application deployed on AWS EC2.</p>

    <div class="grid">
      <div class="card">
        <div class="label">Health Status</div>
        <div class="value green" id="health">Checking...</div>
      </div>

      <div class="card">
        <div class="label">HTTP Port</div>
        <div class="value blue" id="port">-</div>
      </div>

      <div class="card">
        <div class="label">Server Hostname</div>
        <div class="value" id="hostname">-</div>
      </div>

      <div class="card">
        <div class="label">Process Uptime</div>
        <div class="value" id="uptime">-</div>
      </div>
    </div>

    <div class="card" style="margin-top:25px">
      <h3>Health Check</h3>
      <p>Endpoint: GET /health</p>
      <button onclick="checkHealth()">Check Health</button>
      <p id="result"></p>
    </div>

    <div class="footer">
      Built with Node.js | Packer | OpenTofu | AWS
    </div>
  </div>

  <script>
    async function loadStatus() {
      try {
        const response = await fetch('/api/status', {
          cache: 'no-store'
        });

        if (!response.ok) throw new Error('Server unavailable');

        const data = await response.json();

        document.getElementById('health').textContent =
          data.status.toUpperCase();

        document.getElementById('port').textContent = data.port;
        document.getElementById('hostname').textContent =
          data.hostname;

        document.getElementById('uptime').textContent =
          Math.floor(data.uptime / 60) + ' min ' +
          data.uptime % 60 + ' sec';

        document.getElementById('badge').textContent = 'Live';
      } catch (error) {
        document.getElementById('health').textContent = 'Unhealthy';
        document.getElementById('badge').textContent = 'Offline';
      }
    }

    async function checkHealth() {
      const result = document.getElementById('result');

      try {
        const response = await fetch('/health', {
          cache: 'no-store'
        });

        result.textContent = response.ok
          ? '✓ Healthy - HTTP ' + response.status
          : '✗ Unhealthy - HTTP ' + response.status;
      } catch (error) {
        result.textContent = '✗ Health check failed';
      }
    }

    loadStatus();
    setInterval(loadStatus, 5000);
  </script>
</body>
</html>
    `);
    return;
  }

  res.writeHead(404, {
    'Content-Type': 'text/plain'
  });
  res.end('Not Found');
});

server.listen(port, '0.0.0.0', () => {
  console.log('Listening on port ' + port);
  console.log('Hostname: ' + hostname);
});
