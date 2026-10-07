'use strict';
const fs = require('fs');
const path = require('path');
const { Observable, from } = require('rxjs');

// Everything lives in one JSON file: our own metadata plus the neon-lib key/value store.
// The credential inside is a ratchet -- every OTP rewrites keys.j/k/h, tRef and the
// anti-replay stacks -- so writes are atomic (tmp + rename) and the whole operation runs
// under an exclusive lock. Restoring an old copy of this file desyncs the token from the
// server; treat it as live state, not as something to back up and roll back.

const STATE_VERSION = 1;

class State {
  constructor(file) {
    this.file = file;
    this.data = {
      version: STATE_VERSION,
      serial: null,
      dataAppli: null,
      accountId: null,
      credentialId: null,
      serviceId: null,
      deviceName: null,
      enrolledAt: null,
      kv: {},
    };
  }

  exists() { return fs.existsSync(this.file); }

  load() {
    if (!this.exists()) return this;
    const parsed = JSON.parse(fs.readFileSync(this.file, 'utf8'));
    if (parsed.version !== STATE_VERSION) {
      throw new Error(`unsupported state version ${parsed.version} in ${this.file}`);
    }
    this.data = parsed;
    return this;
  }

  save() {
    const tmp = this.file + '.tmp';
    const fd = fs.openSync(tmp, 'w', 0o600);
    try {
      fs.writeFileSync(fd, JSON.stringify(this.data, null, 2));
      fs.fsyncSync(fd);
    } finally {
      fs.closeSync(fd);
    }
    fs.renameSync(tmp, this.file);
    const dir = fs.openSync(path.dirname(this.file), 'r');
    try { fs.fsyncSync(dir); } finally { fs.closeSync(dir); }
  }
}

// ObservableStorageSource, as consumed by neon-lib's RepositoryImpl.
// getKeys() must emit one key per emission -- getAll() pipes it through filter/concatMap.
// Deliberately does NOT define makeIframe (IW.ts calls it when present).
class FileStorageSource {
  constructor(state) { this.state = state; }

  getLength() { return from([Object.keys(this.state.data.kv).length]); }

  getKeys() { return from(Object.keys(this.state.data.kv)); }

  getItem(key) {
    return new Observable((observer) => {
      const v = this.state.data.kv[key];
      observer.next(v === undefined ? null : v);
      observer.complete();
    });
  }

  setItem(key, value) {
    return new Observable((observer) => {
      try {
        this.state.data.kv[key] = value;
        this.state.save();
        observer.next();
        observer.complete();
      } catch (e) { observer.error(e); }
    });
  }

  removeItem(key) {
    return new Observable((observer) => {
      try {
        delete this.state.data.kv[key];
        this.state.save();
        observer.next();
        observer.complete();
      } catch (e) { observer.error(e); }
    });
  }
}

// Exclusive lock. A stale lock from a killed process is reclaimed; a live one is fatal,
// because two concurrent writers would fork the ratchet.
class Lock {
  constructor(file) { this.file = file + '.lock'; this.held = false; }

  acquire() {
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        fs.mkdirSync(this.file);
        fs.writeFileSync(path.join(this.file, 'pid'), String(process.pid));
        this.held = true;
        const release = () => this.release();
        process.on('exit', release);
        process.on('SIGINT', () => { release(); process.exit(130); });
        process.on('SIGTERM', () => { release(); process.exit(143); });
        return;
      } catch (e) {
        if (e.code !== 'EEXIST') throw e;
        const owner = this._owner();
        if (owner !== null && this._alive(owner)) {
          throw new Error(`another tb-otp process (pid ${owner}) holds the lock on ${this.file}`);
        }
        // stale
        try { fs.rmSync(this.file, { recursive: true, force: true }); } catch (_) { /* raced */ }
      }
    }
    throw new Error(`could not acquire lock ${this.file}`);
  }

  _owner() {
    try { return parseInt(fs.readFileSync(path.join(this.file, 'pid'), 'utf8'), 10); }
    catch (_) { return null; }
  }

  _alive(pid) {
    try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
  }

  release() {
    if (!this.held) return;
    this.held = false;
    try { fs.rmSync(this.file, { recursive: true, force: true }); } catch (_) { /* gone */ }
  }
}

module.exports = { State, FileStorageSource, Lock, STATE_VERSION };
