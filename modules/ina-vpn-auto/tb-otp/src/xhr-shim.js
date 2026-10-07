'use strict';
// Minimal XMLHttpRequest over fetch, for Node.
//
// iw-commons-js/lib/http/DefaultHttpProvider.js is the only consumer. It touches exactly:
//   new XMLHttpRequest(), XMLHttpRequest.DONE, open(m,u,async), .timeout, setRequestHeader,
//   send(body), .ontimeout, .onreadystatechange, .readyState, .status, .responseText,
//   addEventListener('error', fn)
// Nothing else -- no cookies, no withCredentials, no response headers.
//
// Two traps from that file drive the design below:
//   1. the readyState handler guards on `status !== null && status !== 0`, so a status of 0
//      is silently swallowed and the request hangs forever. Never report 0 as success.
//   2. it JSON.parses responseText unconditionally, so a non-JSON error page throws a raw
//      SyntaxError out of the handler.

let interceptor = null;

// TB_OTP_DEBUG=1 dumps both legs of the enrollment exchange to stderr.
// The PIN-derived "password" blob is redacted.
const DEBUG = !!process.env.TB_OTP_DEBUG;
function redact(text) {
  if (typeof text !== 'string') return text;
  return text.replace(/("password":")[^"]*(")/g, '$1<redacted>$2');
}
function dbg(line) { process.stderr.write('[http] ' + line + '\n'); }

/** Install a request interceptor. fn(req) -> {status, body} to answer, or null to pass through.
 *  Used by the dry-run mode and the shim tests. */
function setInterceptor(fn) { interceptor = fn; }

class XMLHttpRequestShim {
  constructor() {
    this.readyState = 0;
    this.status = 0;
    this.responseText = '';
    this.timeout = 0;
    this.onreadystatechange = null;
    this.ontimeout = null;
    this._headers = {};
    this._listeners = {};
    this._method = null;
    this._url = null;
  }

  open(method, url) {
    this._method = method;
    this._url = url;
    this.readyState = 1;
  }

  setRequestHeader(name, value) { this._headers[name] = value; }

  addEventListener(type, fn) {
    (this._listeners[type] = this._listeners[type] || []).push(fn);
  }

  _emit(type, ev) { for (const fn of this._listeners[type] || []) fn(ev); }

  _done(status, text) {
    if (DEBUG) dbg(`<- ${status} ${redact(text)}`);
    // status 0 would be swallowed by DefaultHttpProvider's guard; surface it as an error.
    if (!status) { this._emit('error', new Error('no HTTP status from ' + this._url)); return; }
    this.status = status;
    this.responseText = text;
    this.readyState = 4;
    if (this.onreadystatechange) this.onreadystatechange({});
  }

  send(body) {
    const req = { method: this._method, url: this._url, headers: this._headers, body };

    if (DEBUG) {
      dbg(`-> ${this._method} ${this._url}`);
      for (const [k, v] of Object.entries(this._headers)) dbg(`   ${k}: ${v}`);
      dbg(`   ${redact(body)}`);
    }

    if (interceptor) {
      const answer = interceptor(req);
      if (answer) {
        const text = typeof answer.body === 'string' ? answer.body : JSON.stringify(answer.body);
        setImmediate(() => this._done(answer.status, text));
        return;
      }
    }

    const opts = { method: this._method, headers: this._headers };
    if (body !== undefined && body !== null) opts.body = body;
    const ms = Number(this.timeout) || 0;
    if (ms > 0) opts.signal = AbortSignal.timeout(ms);

    fetch(this._url, opts)
      .then(async (res) => this._done(res.status, await res.text()))
      .catch((err) => {
        if (err && (err.name === 'TimeoutError' || err.name === 'AbortError')) {
          if (this.ontimeout) this.ontimeout(err); else this._emit('error', err);
        } else {
          this._emit('error', err);
        }
      });
  }
}

XMLHttpRequestShim.DONE = 4;

function install() { globalThis.XMLHttpRequest = XMLHttpRequestShim; }

module.exports = { XMLHttpRequestShim, install, setInterceptor };
