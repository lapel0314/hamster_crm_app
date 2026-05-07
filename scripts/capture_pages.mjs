import { writeFileSync, mkdirSync } from 'node:fs';

const outDir = new URL('../output/screenshots/', import.meta.url);
mkdirSync(outDir, { recursive: true });

async function getWebSocketUrl() {
  const res = await fetch('http://127.0.0.1:9223/json/new?http://127.0.0.1:5617', { method: 'PUT' });
  const json = await res.json();
  return json.webSocketDebuggerUrl;
}

class CdpClient {
  constructor(url) {
    this.ws = new WebSocket(url);
    this.nextId = 1;
    this.pending = new Map();
    this.ws.addEventListener('message', (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
      }
    });
  }
  ready() {
    return new Promise((resolve) => this.ws.addEventListener('open', resolve, { once: true }));
  }
  send(method, params = {}) {
    const id = this.nextId++;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
  }
  close() { this.ws.close(); }
}

async function delay(ms) { return new Promise((resolve) => setTimeout(resolve, ms)); }

async function click(client, x, y) {
  await client.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await client.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}

async function screenshot(client, filename) {
  const result = await client.send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  writeFileSync(new URL(filename, outDir), Buffer.from(result.data, 'base64'));
}

const pages = [
  { name: '01-dashboard.png', url: 'http://127.0.0.1:5617/?page=dashboard' },
  { name: '02-customer-register.png', url: 'http://127.0.0.1:5617/?page=customer-registration' },
  { name: '03-customer-db.png', url: 'http://127.0.0.1:5617/?page=customers' },
  { name: '04-prospects.png', url: 'http://127.0.0.1:5617/?page=prospects' },
  { name: '05-trash.png', url: 'http://127.0.0.1:5617/?page=trash' },
];

const client = new CdpClient(await getWebSocketUrl());
await client.ready();
await client.send('Page.enable');
await client.send('Runtime.enable');
await client.send('Emulation.setDeviceMetricsOverride', {
  width: 1440,
  height: 1000,
  deviceScaleFactor: 1,
  mobile: false,
});
for (const page of pages) {
  await client.send('Page.navigate', { url: page.url });
  await delay(9000);
  await screenshot(client, page.name);
}

client.close();
console.log('screenshots saved to output/screenshots');
