'use strict';
// Read-only harness against a COPY of the existing desktop credential.
// Confirms the library loads, our storage source satisfies neon-lib's Repository, and
// calculateOption() reports a sane option/format -- WITHOUT generating a code.
// generateOtp() would advance the desktop token's ratchet and desync it from the server,
// so state.save() is fatal here: nothing in this path may write.
const assert = require('assert');
const { State, FileStorageSource } = require('../src/storage');
const { buildConfig } = require('../src/config');

const fixture = process.argv[2];
if (!fixture) { process.stderr.write('usage: offline-harness.js <fixture-state.json>\n'); process.exit(1); }

let failures = 0;
const check = (name, fn) => {
  try { const r = fn(); process.stdout.write(`  ok    ${name}\n`); return r; }
  catch (e) { failures++; process.stdout.write(`  FAIL  ${name}: ${e.message}\n`); }
};

async function main() {
  const state = new State(fixture).load();
  state.save = () => { throw new Error('WRITE ATTEMPTED against the read-only fixture'); };

  const storage = new FileStorageSource(state);

  check('library loads', () => {
    const { IW } = require('../vendor/neon-lib-js');
    assert.strictEqual(IW.LIB_VERSION, '6.13.0');
  });

  const keys = await check('getKeys emits one key per emission', async () => {
    const seen = [];
    await new Promise((res, rej) => storage.getKeys().subscribe({ next: (k) => seen.push(k), error: rej, complete: res }));
    assert.ok(seen.length >= 1, 'no keys');
    assert.ok(seen.every((k) => typeof k === 'string'));
    return seen;
  });

  await check('getLength matches', async () => {
    const n = await storage.getLength().toPromise();
    assert.strictEqual(n, keys.length);
  });

  await check('getItem returns the stored envelope', async () => {
    const v = await storage.getItem(keys[0]).toPromise();
    const parsed = JSON.parse(v);
    assert.strictEqual(parsed.version, 13);
    assert.strictEqual(parsed.type, 'iw_cred_');
    assert.ok(parsed.value.localId);
  });

  await check('getItem for a missing key returns null', async () => {
    assert.strictEqual(await storage.getItem('iw_cred_nope').toPromise(), null);
  });

  const { IW, Operations } = require('../vendor/neon-lib-js');
  const iw = new IW(buildConfig({ serial: state.data.serial, dataAppli: state.data.dataAppli, storageSource: storage }));

  await check('offlineOtp.forService resolves and computes an option (no write)', async () => {
    const op = await iw.offlineOtp.forService(state.data.accountId).toPromise();
    const cred = JSON.parse(state.data.kv[`iw_cred_${state.data.credentialId}`]).value;
    const account = cred.accounts.find((a) => a.serviceId === state.data.serviceId);
    const format = account.secure.substring(3);

    process.stdout.write(`        secure=${account.secure} format=${format}\n`);
    process.stdout.write(`        wikMode=${op.wikMode} wikType=${op.wikChoices[0].wikType}\n`);

    // secure starts with 'b' => PIN required => never option A => MODE_CURRENT + PASSWORD
    assert.ok(account.secure.startsWith('b'), 'expected a PIN-required policy');
    assert.strictEqual(op.wikMode, Operations.WikMode.MODE_CURRENT);
    assert.strictEqual(op.wikChoices[0].wikType, Operations.WikType.PASSWORD);
    assert.ok(['6LC', '7LC', '8LC', '7C', '8C'].includes(format), `unknown format ${format}`);
  });

  check('isStorageSecured is true in our config', () => {
    assert.strictEqual(buildConfig({ serial: 'x' }).isStorageSecured, true);
  });

  check('serverUrl is the app\'s prod endpoint', () => {
    assert.strictEqual(buildConfig({ serial: 'x' }).serverUrl, 'https://ult-inwebo.com');
  });

  process.stdout.write(failures ? `\n${failures} failure(s)\n` : '\nharness passed; fixture untouched\n');
  process.exit(failures ? 1 : 0);
}
main();
