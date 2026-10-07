'use strict';
// Exercises the fetch-backed XMLHttpRequest against a real local server, through the
// actual consumer (iw-commons-js DefaultHttpProvider) rather than against the shim
// directly -- that is what has to work.
const http = require('http');
const assert = require('assert');
const xhr = require('../src/xhr-shim');

xhr.install();
const { http: iwHttp } = require('../vendor/iw-commons-js/lib');

let failures = 0;
const check = async (name, fn) => {
  try { await fn(); process.stdout.write(`  ok    ${name}\n`); }
  catch (e) { failures++; process.stdout.write(`  FAIL  ${name}: ${e.message}\n`); }
};

async function main() {
  const server = http.createServer((req, res) => {
    let body = '';
    req.on('data', (c) => { body += c; });
    req.on('end', () => {
      if (req.url === '/ok') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ echo: JSON.parse(body), ct: req.headers['content-type'], xrid: req.headers['x-request-id'] }));
      } else if (req.url === '/err') {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ code: 'FORBIDDEN', message: 'nope' }));
      } else if (req.url === '/slow') {
        setTimeout(() => { res.writeHead(200); res.end('{}'); }, 2000);
      } else { res.writeHead(404); res.end('{}'); }
    });
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;

  const provider = new iwHttp.DefaultHttpProvider(500);

  await check('2xx JSON round-trip, headers propagated', async () => {
    const r = await provider.post(`${base}/ok`, { hello: 'world' }, { XRequestId: 'abc12345' }).toPromise();
    assert.strictEqual(r.response.statusCode, 200);
    assert.deepStrictEqual(r.body.echo, { hello: 'world' });
    assert.strictEqual(r.body.ct, 'application/json');
    assert.strictEqual(r.body.xrid, 'abc12345');
  });

  await check('non-2xx surfaces status + parsed body', async () => {
    const r = await provider.post(`${base}/err`, {}, {}).toPromise();
    assert.strictEqual(r.response.statusCode, 403);
    assert.strictEqual(r.body.code, 'FORBIDDEN');
  });

  await check('timeout rejects rather than hanging', async () => {
    await assert.rejects(provider.post(`${base}/slow`, {}, {}).toPromise());
  });

  await check('connection refused rejects', async () => {
    await assert.rejects(provider.post('http://127.0.0.1:1/nope', {}, {}).toPromise());
  });

  await check('interceptor answers without touching the network', async () => {
    xhr.setInterceptor((req) => (req.url.endsWith('/intercepted') ? { status: 200, body: { faked: true } } : null));
    const r = await provider.post(`${base}/intercepted`, {}, {}).toPromise();
    assert.strictEqual(r.body.faked, true);
    xhr.setInterceptor(null);
  });

  await check('XMLHttpRequest.DONE === 4', async () => {
    assert.strictEqual(globalThis.XMLHttpRequest.DONE, 4);
  });

  server.close();
  process.stdout.write(failures ? `\n${failures} failure(s)\n` : '\nall shim tests passed\n');
  process.exit(failures ? 1 : 0);
}
main();
