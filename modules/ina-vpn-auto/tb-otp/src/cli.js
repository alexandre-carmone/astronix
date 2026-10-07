#!/usr/bin/env node
'use strict';
const os = require('os');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { State, FileStorageSource, Lock } = require('./storage');
const { readMachineSerial, buildConfig, PROD } = require('./config');
const xhr = require('./xhr-shim');

function defaultStatePath() {
  if (process.env.TB_OTP_STATE) return process.env.TB_OTP_STATE;
  const base = process.env.XDG_STATE_HOME
    || path.join(os.homedir(), '.local', 'state');
  return path.join(base, 'tb-otp', 'state.json');
}
const DEFAULT_STATE = defaultStatePath();

function usage() {
  process.stderr.write(`tb-otp -- headless OTP for TrustBuilder / inWebo Authenticator 6

  tb-otp enroll --code <activation-code> [--name <device name>] [--dry-run]
      Enroll a new token. Prompts for a PIN (twice). One-time; the activation
      code is consumed. --dry-run prints the setup request and sends nothing.

  tb-otp otp
      Print one OTP to stdout. No network. PIN from $TB_OTP_PIN, then the
      keyring, else a prompt. Every run advances the ratchet and rewrites state.

  tb-otp status
      Show account metadata and ratchet state. Read-only; does not generate a code.

  tb-otp set-pin
      Store the PIN in gnome-keyring so 'otp' needs no prompt and no env var.

Options:
  --state <file>   state file (default: ${DEFAULT_STATE})

Environment:
  TB_OTP_PIN       PIN, to avoid the interactive prompt
                   (otherwise: gnome-keyring service=tb-otp account=pin, else prompt)
  TB_OTP_STATE     default state file path
`);
}

function parseArgs(argv) {
  const out = { _: [], state: DEFAULT_STATE };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--code') out.code = argv[++i];
    else if (a === '--name') out.name = argv[++i];
    else if (a === '--state') out.state = argv[++i];
    else if (a === '--dry-run') out.dryRun = true;
    else if (a === '-h' || a === '--help') out.help = true;
    else out._.push(a);
  }
  return out;
}

// Prompts go to stderr so stdout carries only the OTP.
function promptHidden(label) {
  return new Promise((resolve, reject) => {
    const stdin = process.stdin;
    if (!stdin.isTTY) {
      reject(new Error('no TTY available for the PIN prompt; set TB_OTP_PIN instead'));
      return;
    }
    process.stderr.write(label);
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding('utf8');
    let buf = '';
    const cleanup = () => {
      stdin.removeListener('data', onData);
      stdin.setRawMode(false);
      stdin.pause();
    };
    const onData = (ch) => {
      if (ch === '\r' || ch === '\n') {
        cleanup();
        process.stderr.write('\n');
        resolve(buf);
      } else if (ch === '\u0003') { // ctrl-c
        cleanup();
        process.stderr.write('\n');
        reject(new Error('aborted'));
      } else if (ch === '\u007f' || ch === '\b') {
        buf = buf.slice(0, -1);
      } else {
        buf += ch;
      }
    };
    stdin.on('data', onData);
  });
}

const KEYRING_SERVICE = process.env.TB_OTP_KEYRING_SERVICE || 'tb-otp';
const KEYRING_ACCOUNT = process.env.TB_OTP_KEYRING_ACCOUNT || 'pin';

// secret-tool exits non-zero when the entry is absent; that is not an error here.
function pinFromKeyring() {
  try {
    const out = execFileSync('secret-tool',
      ['lookup', 'service', KEYRING_SERVICE, 'account', KEYRING_ACCOUNT],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    return out || null;
  } catch (_) {
    return null;
  }
}

// $TB_OTP_PIN, then gnome-keyring, then a prompt. The keyring path is what makes
// `tb-otp otp` usable from another script with no secrets on its command line.
async function getPin() {
  if (process.env.TB_OTP_PIN) return process.env.TB_OTP_PIN;
  const stored = pinFromKeyring();
  if (stored) return stored;
  return promptHidden('PIN: ');
}

async function cmdSetPin(args) {
  const pin = await promptHidden('PIN to store in the keyring: ');
  const again = await promptHidden('Confirm: ');
  if (pin !== again) throw new Error('PINs did not match');
  if (!pin) throw new Error('empty PIN');
  execFileSync('secret-tool',
    ['store', '--label=tb-otp inWebo PIN', 'service', KEYRING_SERVICE, 'account', KEYRING_ACCOUNT],
    { input: pin });
  process.stderr.write(`stored under service=${KEYRING_SERVICE} account=${KEYRING_ACCOUNT}\n`);
}

function makeIw(state, storageSource) {
  const { IW } = require('../vendor/neon-lib-js');
  return new IW(buildConfig({
    serial: state.data.serial,
    dataAppli: state.data.dataAppli,
    storageSource,
  }));
}

function describeError(e) {
  if (!e) return 'unknown error';
  // IWError carries {code, message}
  if (e.code && e.message && e.code !== e.message) return `${e.code}: ${e.message}`;
  return e.code || e.message || String(e);
}

async function cmdEnroll(args) {
  if (!args.code) throw new Error('--code is required');

  const state = new State(args.state);
  if (state.exists()) {
    throw new Error(
      `${args.state} already exists -- refusing to re-enroll over a live token.\n`
      + 'Move it aside first if you really mean to enroll again.');
  }

  fs.mkdirSync(path.dirname(args.state), { recursive: true, mode: 0o700 });

  // Captured once, replayed forever: getKma() re-derives from this on every OTP.
  state.data.serial = readMachineSerial();
  state.data.dataAppli = PROD.dataAppli;

  xhr.install();

  if (args.dryRun) {
    xhr.setInterceptor((req) => {
      process.stderr.write('--- DRY RUN: request that would be sent ---\n');
      process.stderr.write(`${req.method} ${req.url}\n`);
      for (const [k, v] of Object.entries(req.headers)) process.stderr.write(`${k}: ${v}\n`);
      process.stderr.write('\n' + req.body + '\n');
      process.stderr.write('--- nothing was sent; activation code NOT consumed ---\n');
      process.exit(0);
    });
  }

  const deviceName = args.name || `${os.hostname()}-cli`;
  const storage = new FileStorageSource(state);
  const iw = makeIw(state, storage);
  const { Operations } = require('../vendor/neon-lib-js');

  // Gather the PIN FIRST. The server's enrollment code entry is short-lived: a human
  // typing at a prompt between setup and finalize is enough for it to disappear, and it
  // does not come back -- the activation code is then dead. So: prompt, then fire both
  // legs back to back.
  let suppliedPin = process.env.TB_OTP_PIN || '';
  if (!suppliedPin) {
    process.stderr.write(
      'Enter the PIN for this account. Normally this is the EXISTING PIN you already use\n'
      + 'for TrustBuilder; if the server asks you to define a new one, this becomes it.\n');
    suppliedPin = await promptHidden('PIN: ');
    const again = await promptHidden('Confirm PIN: ');
    if (again !== suppliedPin) throw new Error('PINs did not match');
    if (!suppliedPin) throw new Error('empty PIN');
  }

  process.stderr.write('Contacting enrollment/setup...\n');
  const tSetup = Date.now();
  const op = await iw.enrollment.startEnrollment(args.code).toPromise();

  // The server dictates which PIN it wants, exactly as the desktop app's activate() does:
  //   MODE_NONE    -> no PIN at all
  //   MODE_CURRENT -> askForPIN(...)  : the PIN you ALREADY use for this account
  //   MODE_NEW     -> definePin(...)  : this PIN becomes the token's new one
  const WM = Operations.WikMode;
  let pin = '';
  if (op.wikMode === WM.MODE_NONE) {
    process.stderr.write('Server requires no PIN for this token; ignoring the one supplied.\n');
  } else if (op.wikMode === WM.MODE_CURRENT) {
    process.stderr.write('Server wants the EXISTING PIN for this account -- using it.\n');
    pin = suppliedPin;
  } else if (op.wikMode === WM.MODE_NEW) {
    process.stderr.write('Server wants a NEW PIN -- the one you supplied becomes this token\'s PIN.\n');
    pin = suppliedPin;
  } else {
    throw new Error(`unexpected wikMode ${op.wikMode}`);
  }
  if (op.wikMode !== WM.MODE_NONE && !pin) throw new Error('empty PIN');

  process.stderr.write(`Contacting enrollment/finalize as "${deviceName}" `
    + `(+${Date.now() - tSetup}ms since setup)...\n`);
  // EXACTLY two arguments. A truthy third hits `filter(_ => publicKeyCredential == undefined)`
  // and the observable completes with zero emissions -- a silent no-op that burns the code.
  const accountId = await op.finalize(pin, deviceName).toPromise();

  if (!accountId) {
    throw new Error('enrollment finalize produced no accountId -- nothing was persisted');
  }

  const id = JSON.parse(Buffer.from(accountId, 'base64').toString('utf8'));
  state.data.accountId = accountId;
  state.data.credentialId = id.credentialId;
  state.data.serviceId = id.serviceId;
  state.data.deviceName = deviceName;
  state.data.enrolledAt = new Date().toISOString();
  state.save();

  process.stderr.write('\nEnrolled.\n');
  process.stderr.write(`  state       ${args.state}\n`);
  process.stderr.write(`  accountId   ${accountId}\n`);
  process.stderr.write(`  credential  ${id.credentialId}\n`);
  process.stderr.write(`  service     ${id.serviceId}\n`);
  process.stderr.write('\nGenerate a code with:  tb-otp otp\n');
}

async function cmdOtp(args) {
  // Deliberately no xhr.install() here: offline OTP must never touch the network, and an
  // undefined XMLHttpRequest turns any accidental request into a loud failure.
  const state = new State(args.state).load();
  if (!state.data.accountId) throw new Error(`no enrolled token in ${args.state}; run: tb-otp enroll`);

  const lock = new Lock(args.state);
  lock.acquire();
  try {
    const { Operations } = require('../vendor/neon-lib-js');
    const storage = new FileStorageSource(state);
    const iw = makeIw(state, storage);

    const op = await iw.offlineOtp.forService(state.data.accountId).toPromise();
    const wikType = op.wikChoices[0].wikType;
    const pin = wikType === Operations.WikType.NONE ? '' : await getPin();

    const otp = await op.finalize(pin, wikType).toPromise();
    if (!otp) throw new Error('no OTP produced');
    process.stdout.write(otp + '\n');
  } finally {
    lock.release();
  }
}

async function cmdStatus(args) {
  const state = new State(args.state).load();
  if (!state.data.accountId) throw new Error(`no enrolled token in ${args.state}; run: tb-otp enroll`);

  const key = `iw_cred_${state.data.credentialId}`;
  const cred = JSON.parse(state.data.kv[key]).value;
  const account = cred.accounts.find((a) => a.serviceId === state.data.serviceId);

  const secure = account.secure;
  const format = secure.substring(3);
  const now = Date.now();
  const d2 = 45 * 1000;
  const ago = (t) => {
    const ms = now - new Date(t).valueOf();
    return ms > 1e12 ? 'never' : `${Math.floor(ms / 1000)}s ago`;
  };
  const early = (now - new Date(cred.offlineState.lastT1).valueOf() < 5 * d2)
    || (now - new Date(cred.offlineState.lastT2).valueOf() < 13 * d2)
    || (now - new Date(cred.offlineState.lastT3).valueOf() < 20 * d2);

  const out = [
    `state file    ${args.state}`,
    `enrolled      ${state.data.enrolledAt}`,
    `device name   ${state.data.deviceName}`,
    `account       ${account.i18nServiceName && account.i18nServiceName.en} (service ${account.serviceId}) login=${account.login}`,
    `accountId     ${state.data.accountId}`,
    `credential    ${cred.localId}`,
    `revision      ${cred.revision}`,
    `blocked       ${cred.isBlocked}`,
    `pin state     ${cred.passwordState}   (secure=${secure}, ${format} format)`,
    `online otp    ${account.onlineOTP}`,
    `tSync         ${cred.tSync}`,
    `tRef          ${cred.keys.tRef}`,
    `last codes    T1 ${ago(cred.offlineState.lastT1)} | T2 ${ago(cred.offlineState.lastT2)} | T3 ${ago(cred.offlineState.lastT3)}`,
    `burst window  ${early ? 'YES -- next code escalates to option B2/Bp' : 'no -- next code uses the normal option'}`,
    `cancelPin     ${cred.offlineState.cancelPin}   nbOkA ${cred.offlineState.nbOkA}   lastBp ${cred.offlineState.lastBp}`,
  ];
  process.stdout.write(out.join('\n') + '\n');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const cmd = args._[0];
  if (args.help || !cmd) { usage(); process.exit(cmd ? 0 : 1); }

  if (cmd === 'enroll') await cmdEnroll(args);
  else if (cmd === 'otp') await cmdOtp(args);
  else if (cmd === 'status') await cmdStatus(args);
  else if (cmd === 'set-pin') await cmdSetPin(args);
  else { process.stderr.write(`unknown command: ${cmd}\n`); usage(); process.exit(1); }
}

main().then(
  () => process.exit(0),
  (e) => { process.stderr.write('error: ' + describeError(e) + '\n'); process.exit(1); },
);
