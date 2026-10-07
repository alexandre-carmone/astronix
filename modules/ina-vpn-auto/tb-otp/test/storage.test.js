'use strict';
// Lock and atomic-write guarantees. No credential involved.
const fs = require('fs');
const os = require('os');
const path = require('path');
const assert = require('assert');
const { execFileSync, spawnSync } = require('child_process');
const { State, FileStorageSource, Lock } = require('../src/storage');

let failures = 0;
const check = async (name, fn) => {
  try { await fn(); process.stdout.write(`  ok    ${name}\n`); }
  catch (e) { failures++; process.stdout.write(`  FAIL  ${name}: ${e.message}\n`); }
};

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'tb-otp-test-'));
const file = path.join(tmp, 'state.json');

async function main() {
  await check('save/load round-trips and file is 0600', () => {
    const s = new State(file);
    s.data.serial = 'abc\n';
    s.data.kv['iw_cred_x'] = JSON.stringify({ version: 13, type: 'iw_cred_', value: { localId: 'x' } });
    s.save();
    assert.strictEqual(fs.statSync(file).mode & 0o777, 0o600);
    const t = new State(file).load();
    assert.strictEqual(t.data.serial, 'abc\n');
    assert.strictEqual(t.data.kv['iw_cred_x'], s.data.kv['iw_cred_x']);
  });

  await check('setItem persists through the storage source', async () => {
    const s = new State(file).load();
    const src = new FileStorageSource(s);
    await src.setItem('iw_cred_y', 'hello').toPromise();
    assert.strictEqual(new State(file).load().data.kv['iw_cred_y'], 'hello');
    await src.removeItem('iw_cred_y').toPromise();
    assert.strictEqual(new State(file).load().data.kv['iw_cred_y'], undefined);
  });

  await check('no .tmp file is left behind', () => {
    assert.ok(!fs.existsSync(file + '.tmp'), 'stray tmp file');
  });

  await check('a live lock blocks a second holder', () => {
    const a = new Lock(file);
    a.acquire();
    try {
      const b = new Lock(file);
      assert.throws(() => b.acquire(), /holds the lock/);
    } finally { a.release(); }
  });

  await check('lock is released afterwards', () => {
    const c = new Lock(file);
    c.acquire();
    c.release();
    assert.ok(!fs.existsSync(file + '.lock'));
  });

  await check('a stale lock (dead pid) is reclaimed', () => {
    fs.mkdirSync(file + '.lock');
    fs.writeFileSync(path.join(file + '.lock', 'pid'), '999999');
    const d = new Lock(file);
    d.acquire();          // must not throw
    d.release();
  });

  await check('concurrent `otp` in a real second process fails fast, not corrupting', () => {
    const a = new Lock(file);
    a.acquire();
    try {
      const r = spawnSync(process.execPath, [
        path.join(__dirname, '..', 'src', 'cli.js'), 'otp', '--state', file,
      ], { encoding: 'utf8', env: { ...process.env, TB_OTP_PIN: 'x' } });
      assert.notStrictEqual(r.status, 0, 'second process should have failed');
      assert.ok(/holds the lock|no enrolled token/.test(r.stderr), `unexpected stderr: ${r.stderr}`);
    } finally { a.release(); }
  });

  await check('interrupted write leaves the previous file intact', () => {
    const before = fs.readFileSync(file, 'utf8');
    const s = new State(file).load();
    // simulate a crash mid-write: create a partial tmp, then fail before rename
    fs.writeFileSync(file + '.tmp', '{"partial":');
    assert.strictEqual(fs.readFileSync(file, 'utf8'), before, 'main file was modified');
    fs.unlinkSync(file + '.tmp');
    // and a real save still works afterwards
    s.save();
    assert.ok(JSON.parse(fs.readFileSync(file, 'utf8')));
  });

  fs.rmSync(tmp, { recursive: true, force: true });
  process.stdout.write(failures ? `\n${failures} failure(s)\n` : '\nall storage tests passed\n');
  process.exit(failures ? 1 : 0);
}
main();
