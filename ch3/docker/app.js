
const http = require('http');
const os = require('os');

const port = Number(process.env.PORT || 8080);
const hostname = os.hostname();

const page = String.raw`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Sample App | DevOps Dashboard</title>
  <style>
    :root {
      --yellow: #ffe500;
      --turquoise: #49cbbf;
      --pink: #f000e8;
      --ink: #111111;
      --white: #ffffff;
      --muted: #686868;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 44px 18px 66px;
      min-height: 100vh;
      background: var(--yellow);
      color: var(--ink);
      font-family: Arial, Helvetica, sans-serif;
    }
    .shell {
      max-width: 1060px;
      margin: auto;
      background: var(--white);
      border: 2px solid var(--ink);
      box-shadow: 9px 9px 0 var(--ink);
      overflow: hidden;
    }
    .topbar {
      min-height: 68px;
      padding: 14px 32px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
    }
    .logo {
      display: inline-flex;
      align-items: center;
      gap: 12px;
      font-weight: 900;
      letter-spacing: -.5px;
    }
    .logo-mark {
      display: inline-flex;
      align-items: center;
    }
    .logo-mark i {
      width: 20px;
      height: 20px;
      background: var(--pink);
      border: 2px solid var(--ink);
      border-radius: 50%;
      margin-left: -5px;
    }
    .logo-mark i:first-child { margin-left: 0; }
    .top-right {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .top-label {
      text-transform: uppercase;
      letter-spacing: 1.5px;
      font-size: 11px;
      font-weight: 800;
    }
    .top-pill {
      border: 2px solid var(--ink);
      border-radius: 30px;
      background: white;
      padding: 7px 13px;
      font-weight: 900;
      font-size: 12px;
    }
    .hero {
      background: var(--turquoise);
      border-top: 2px solid var(--ink);
      border-bottom: 2px solid var(--ink);
      padding: 53px 45px 49px;
      display: grid;
      grid-template-columns: minmax(0, 1.15fr) minmax(260px, .85fr);
      gap: 20px;
      min-height: 320px;
    }
    .eyebrow {
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 2px;
      text-transform: uppercase;
      margin: 0 0 15px;
    }
    h1 {
      font-size: clamp(38px, 5.3vw, 66px);
      line-height: .99;
      letter-spacing: -2px;
      margin: 0 0 23px;
      font-weight: 950;
    }
    .hero p {
      max-width: 430px;
      font-size: 15px;
      line-height: 1.5;
      font-weight: 600;
      margin: 0 0 23px;
    }
    .pill-button {
      padding: 11px 21px;
      border: 2px solid var(--ink);
      border-radius: 100px;
      background: white;
      box-shadow: 3px 3px 0 var(--ink);
      font-weight: 900;
      cursor: pointer;
      text-transform: uppercase;
      transition: transform .1s, box-shadow .1s;
    }
    .pill-button:hover {
      transform: translate(2px,2px);
      box-shadow: 1px 1px 0 var(--ink);
    }
    .art {
      position: relative;
      min-height: 220px;
    }
    .dots {
      position: absolute;
      top: 5px;
      left: 4%;
      width: 55px;
      height: 45px;
      background-image: radial-gradient(var(--ink) 1.3px, transparent 1.3px);
      background-size: 12px 12px;
    }
    .window {
      position: absolute;
      top: 14px;
      right: 7%;
      width: 69%;
      height: 170px;
      border: 3px solid var(--ink);
      background: var(--pink);
      box-shadow: 5px 5px 0 var(--ink);
    }
    .window-bar {
      height: 28px;
      background: #fff;
      border-bottom: 3px solid var(--ink);
      display: flex;
      align-items: center;
      gap: 5px;
      padding-left: 10px;
    }
    .window-bar span {
      height: 8px;
      width: 8px;
      background: var(--ink);
      border-radius: 50%;
    }
    .window-code {
      display: flex;
      align-items: center;
      justify-content: center;
      height: calc(100% - 28px);
      font-size: 68px;
      font-weight: 900;
      letter-spacing: -6px;
    }
    .search-shape {
      position: absolute;
      right: -2%;
      top: 115px;
      width: 56%;
      height: 39px;
      border: 2px solid var(--ink);
      background: #fff;
      border-radius: 40px;
      box-shadow: 3px 3px 0 var(--ink);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 12px;
    }
    .search-line {
      height: 18px;
      border-left: 2px solid var(--ink);
      margin-left: 8px;
    }
    .magnifier {
      width: 15px;
      height: 15px;
      border: 2px solid var(--ink);
      border-radius: 50%;
      position: relative;
    }
    .magnifier::after {
      content: '';
      position: absolute;
      height: 8px;
      border-left: 2px solid var(--ink);
      transform: rotate(-43deg);
      top: 11px;
      left: 13px;
    }
    .mini-window {
      position: absolute;
      left: 7%;
      bottom: 1px;
      background: #fff;
      border: 2px solid var(--ink);
      width: 108px;
      height: 42px;
      box-shadow: 3px 3px 0 var(--ink);
    }
    .mini-window::before {
      content: '•••';
      display: block;
      text-align: right;
      height: 13px;
      background: var(--pink);
      border-bottom: 2px solid var(--ink);
      line-height: 9px;
      padding-right: 6px;
    }
    .mini-window::after {
      content: '✱ ✱ ✱';
      display: block;
      text-align: center;
      font-weight: 900;
      line-height: 25px;
    }
    .content {
      padding: 36px 32px 44px;
    }
    .section-header {
      display: flex;
      align-items: end;
      justify-content: space-between;
      gap: 10px;
      margin-bottom: 20px;
    }
    h2 {
      margin: 0;
      font-size: 26px;
      font-weight: 950;
      letter-spacing: -.8px;
    }
    .hint {
      color: var(--muted);
      font-size: 12px;
      font-weight: 700;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 16px;
    }
    .metric-card {
      border: 2px solid var(--ink);
      border-radius: 7px;
      overflow: hidden;
      box-shadow: 4px 4px 0 var(--ink);
      min-width: 0;
    }
    .metric-visual {
      min-height: 111px;
      background: var(--turquoise);
      border-bottom: 2px solid var(--ink);
      padding: 15px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }
    .metric-icon {
      width: 28px;
      height: 28px;
      display: grid;
      place-items: center;
      border: 2px solid var(--ink);
      border-radius: 50%;
      background: #00ecdf;
      font-size: 19px;
      font-weight: 900;
    }
    .metric-value {
      font-size: clamp(17px, 2.1vw, 25px);
      letter-spacing: -.6px;
      font-weight: 900;
      overflow-wrap: anywhere;
    }
    .metric-info {
      padding: 13px 14px 15px;
      background: white;
    }
    .metric-label {
      font-size: 12px;
      text-transform: uppercase;
      font-weight: 900;
      margin-bottom: 9px;
    }
    .rule {
      width: 85%;
      height: 5px;
      background: #e6e6e6;
      margin-bottom: 5px;
    }
    .rule.short { width: 52%; }
    .diagnostics {
      margin-top: 34px;
      border: 2px solid var(--ink);
      box-shadow: 4px 4px 0 var(--ink);
      padding: 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 20px;
    }
    .diagnostics h3 {
      margin: 0 0 7px;
      font-size: 21px;
    }
    .diagnostics p {
      margin: 0;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.6;
    }
    #result {
      margin-top: 9px;
      color: #075f3b;
      font-weight: 800;
    }
    .action {
      background: var(--pink);
      white-space: nowrap;
      border-radius: 4px;
    }
    .footer {
      padding: 0 32px 24px;
      text-align: center;
      font-size: 12px;
      font-weight: 700;
      color: var(--muted);
    }
    .offline { background: #ffb6b6 !important; }

    @media (max-width: 780px) {
      .grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .hero { padding: 38px 25px; }
      .content { padding: 28px 22px 38px; }
    }
    @media (max-width: 560px) {
      body { padding: 14px 10px 34px; }
      .topbar { padding: 13px 16px; }
      .logo { font-size: 13px; }
      .top-label { display: none; }
      .hero {
        grid-template-columns: 1fr;
        padding: 33px 22px 23px;
      }
      .art {
        min-height: 205px;
        max-width: 360px;
        width: 100%;
        margin: auto;
      }
      .grid { gap: 12px; }
      .metric-visual { min-height: 110px; padding: 12px; }
      .metric-info { padding: 11px; }
      .diagnostics {
        flex-direction: column;
        align-items: stretch;
      }
      .action { width: 100%; }
    }
  </style>
</head>
<body>
  <main class="shell">
    <nav class="topbar">
      <div class="logo">
        <span class="logo-mark" aria-hidden="true">
          <i></i><i></i><i></i>
        </span>
        SAMPLE APP
      </div>
      <div class="top-right">
        <span class="top-label">DevOps Lab / 001</span>
        <span class="top-pill" id="badge">● LIVE</span>
      </div>
    </nav>

    <section class="hero">
      <div>
        <p class="eyebrow">Node.js / AWS EC2 / Infrastructure</p>
        <h1>Server<br>Dashboard<span style="color:var(--pink)">.</span></h1>
        <p>
          Bold infrastructure monitoring. Live server metrics,
          health checks, and a little retro web energy.
        </p>
        <button class="pill-button"
          onclick="document.getElementById('overview').scrollIntoView({behavior:'smooth'})">
          Explore ↗
        </button>
      </div>

      <div class="art" aria-hidden="true">
        <div class="dots"></div>
        <div class="window">
          <div class="window-bar">
            <span></span><span></span><span></span>
          </div>
          <div class="window-code">&lt;/&gt;</div>
        </div>
        <div class="search-shape">
          <span class="search-line"></span>
          <span class="magnifier"></span>
        </div>
        <div class="mini-window"></div>
      </div>
    </section>

    <section class="content" id="overview">
      <div class="section-header">
        <h2>System overview ✳</h2>
        <span class="hint">AUTO-REFRESH / 5 SEC</span>
      </div>

      <div class="grid">
        <article class="metric-card">
          <div class="metric-visual" id="health-panel">
            <div class="metric-icon">+</div>
            <div class="metric-value" id="health">CHECKING...</div>
          </div>
          <div class="metric-info">
            <div class="metric-label">Health Status</div>
            <div class="rule"></div>
            <div class="rule short"></div>
          </div>
        </article>

        <article class="metric-card">
          <div class="metric-visual">
            <div class="metric-icon">↗</div>
            <div class="metric-value" id="port">—</div>
          </div>
          <div class="metric-info">
            <div class="metric-label">HTTP Port</div>
            <div class="rule"></div>
            <div class="rule short"></div>
          </div>
        </article>

        <article class="metric-card">
          <div class="metric-visual">
            <div class="metric-icon">⌘</div>
            <div class="metric-value" id="hostname">—</div>
          </div>
          <div class="metric-info">
            <div class="metric-label">Server Hostname</div>
            <div class="rule"></div>
            <div class="rule short"></div>
          </div>
        </article>

        <article class="metric-card">
          <div class="metric-visual">
            <div class="metric-icon">◷</div>
            <div class="metric-value" id="uptime">—</div>
          </div>
          <div class="metric-info">
            <div class="metric-label">Process Uptime</div>
            <div class="rule"></div>
            <div class="rule short"></div>
          </div>
        </article>
      </div>

      <section class="diagnostics">
        <div>
          <h3>Health check ✦</h3>
          <p>
            Verify that the application is responding.<br>
            <strong>Endpoint: GET /health</strong>
          </p>
          <p id="result" aria-live="polite"></p>
        </div>
        <button class="pill-button action" id="check-button"
          onclick="checkHealth()">
          Check Health →
        </button>
      </section>
    </section>

    <footer class="footer">
      BUILT WITH NODE.JS ✳ PACKER ✳ OPENTOFU ✳ AWS
    </footer>
  </main>

  <script>
    async function loadStatus() {
      try {
        const response = await fetch('/api/status', {
          cache: 'no-store'
        });

        if (!response.ok) throw new Error('Server unavailable');

        const data = await response.json();

        document.getElementById('health').textContent =
          String(data.status).toUpperCase();

        document.getElementById('port').textContent = data.port;
        document.getElementById('hostname').textContent = data.hostname;

        document.getElementById('uptime').textContent =
          Math.floor(data.uptime / 60) + ' min ' +
          data.uptime % 60 + ' sec';

        document.getElementById('badge').textContent = '● LIVE';
        document.getElementById('health-panel').classList.remove('offline');

      } catch (error) {
        document.getElementById('health').textContent = 'UNHEALTHY';
        document.getElementById('badge').textContent = '● OFFLINE';
        document.getElementById('health-panel').classList.add('offline');
      }
    }

    async function checkHealth() {
      const result = document.getElementById('result');
      const button = document.getElementById('check-button');

      button.disabled = true;
      result.textContent = 'Checking...';

      try {
        const response = await fetch('/health', {
          cache: 'no-store'
        });

        result.textContent = response.ok
          ? '✓ Healthy — HTTP ' + response.status
          : '✗ Unhealthy — HTTP ' + response.status;

      } catch (error) {
        result.textContent = '✗ Health check failed';
      } finally {
        button.disabled = false;
      }
    }

    loadStatus();
    setInterval(loadStatus, 5000);
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store'
    });
    res.end(JSON.stringify({ status: 'healthy' }));
    return;
  }

  if (req.method === 'GET' && req.url === '/api/status') {
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store'
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

  if (req.method === 'GET' && req.url === '/') {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8'
    });
    res.end(page);
    return;
  }

  res.writeHead(404, {
    'Content-Type': 'text/plain; charset=utf-8'
  });
  res.end('Not Found');
});

server.listen(port, '0.0.0.0', () => {
  console.log('Listening on port ' + port);
  console.log('Hostname: ' + hostname);
});
