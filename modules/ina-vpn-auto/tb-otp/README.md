# tb-otp

Headless OTP generator for **TrustBuilder / inWebo Authenticator 6** (service 2314, INA).

Authenticator 6 does **not** use RFC-6238 TOTP, so its credential cannot be exported to
Bitwarden or Ente Auth. Its OTP is a proprietary *stateful ratchet*. This CLI drives
inWebo's own client library (`neon-lib-js` 6.13.0, vendored from the app's asar) headlessly
instead of reimplementing it.

## Setup

Do these steps one time, on each machine.

```sh
./scripts/extract-vendor.sh      # 1. build vendor/ from your own TrustBuilder
tb-otp enroll --code <code>      # 2. enroll YOUR token (see below)
tb-otp set-pin                   # 3. put your PIN in the keyring
```

1. **`vendor/`** is not in this repository. The script finds Authenticator 6 on your
   machine, unpacks `app.asar`, and copies inWebo's library out of it. Set `TB_ASAR` if
   the search does not find the file. You need `node`; you do not need NixOS.
2. **Get your own activation code** from INA selfcare, or from the person who administers
   inWebo service 2314. The code works one time. Read *Enrollment: hard-won details*
   below first -- a failed attempt destroys the code.
   You cannot copy another person's token. `state.json` holds one identity and one
   ratchet, and two machines cannot share it.
3. The PIN is the PIN you already use for TrustBuilder. The server sets the rule:
   4 to 6 digits, numbers only.

For `ina-vpn`, put your INA username in `~/.config/ina-vpn.env`:

```sh
echo 'INA_LOGIN=<your sso user>' > ~/.config/ina-vpn.env && chmod 600 ~/.config/ina-vpn.env
```

## Usage

```sh
tb-otp enroll --code <activation-code> [--name <device name>]   # once, interactive
tb-otp otp                                                      # prints one code
tb-otp status                                                   # read-only inspection
```

`otp` resolves the PIN from `$TB_OTP_PIN`, then gnome-keyring
(`service=tb-otp account=pin`, override with `$TB_OTP_KEYRING_SERVICE` /
`$TB_OTP_KEYRING_ACCOUNT`), then an interactive prompt. Store it once with
`tb-otp set-pin` and it runs unattended. Only the code goes to stdout, so it pipes
cleanly:

```sh
TB_OTP_PIN=... tb-otp otp | xclip -selection clipboard
```

State lives at `$XDG_STATE_HOME/tb-otp/state.json` (default `~/.local/state/tb-otp/`),
mode 0600. Override with `--state` or `$TB_OTP_STATE`.

## INA VPN

`bin/ina-vpn` is the VPN script. Install it with
`install -m755 bin/ina-vpn ~/.local/bin/ina-vpn`. It uses tb-otp for its 2FA step. It picks a generator in this order:
`$INA_OTP_CMD`, then `tb-otp` on PATH, then `~/tb-otp/src/cli.js`; `INA_OTP_CMD=-`
forces typing the code by hand. The **third** login attempt always falls back to a manual
prompt, so a desynced ratchet or a wrong PIN can never lock you out of the VPN.

Put tb-otp on PATH with `ln -s "$PWD/src/cli.js" ~/.local/bin/tb-otp`.

## Nix

```sh
nix run .#tb-otp -- status
nix develop            # devshell with node
```

Nix is optional. The usual way to run the tool is `src/cli.js`, which needs no build.
A flake build reads only the files that Git tracks, and `vendor/` is not tracked. So run
`git add -f vendor` before `nix build`, or keep to the plain `node` path.

## How it works

| | |
|---|---|
| `src/config.js` | inWebo prod config lifted verbatim from the app (`https://ult-inwebo.com`, `macId=0`, `dataAppli=shell`, prod `kFactory`, …) |
| `src/xhr-shim.js` | fetch-backed `XMLHttpRequest`; the vendored HTTP provider is XHR-only. Enrollment only |
| `src/storage.js` | `ObservableStorageSource` over one atomic JSON file, plus an exclusive lock |
| `src/cli.js` | `enroll` / `otp` / `status` |

Enrollment is two HTTP calls (`v3 enrollment/setup` then `enrollment/finalize`, sharing one
`X-Request-Id`), plus a probable third `tosec` sync. **Generating a code makes no network
requests at all** — `otp` deliberately does not install the XHR shim, so any accidental
request fails loudly instead of silently phoning home.

## Enrollment: hard-won details

- **The activation code is fragile.** The server's code entry does not survive a failed
  `enrollment/finalize`: one bad attempt and both legs return
  `CODE_ENTRY_DOES_NOT_EXIST` from then on, and you need a fresh code. So the CLI
  collects the PIN *before* calling `enrollment/setup` and fires both legs back to back
  (observed: +116ms). Never leave a human prompt between them.
- **`wikMode` decides which PIN the server wants**, exactly as the desktop app's
  `activate()` does. `MODE_CURRENT` (1) means your **existing** account PIN, not a new
  one -- getting this wrong is what burns activation codes.
- **The PIN policy comes back in `wikRule`** on the setup response. For service 2314 it is
  `{min:4, max:6, acceptnumerical:true, acceptalpha:false}` -- 4 to 6 digits, numeric only.
- **Enrollment is three calls, not two**, when the server sets `tosecRequired` (it does
  here): `v3 enrollment/setup` -> `v3 enrollment/finalize` -> `v2 tosec/synchronize`,
  all sharing one `X-Request-Id`.
- `TB_OTP_DEBUG=1` traces every request and response to stderr, with the PIN-derived
  `password` blob redacted.

## Things that will bite you

- **Never restore an old `state.json`.** Every code rewrites `keys.j/k/h`, `tRef` and the
  anti-replay stacks. A stale copy desyncs from the server and can block the token. It is
  live state, not a backup artifact.
- **One writer.** Two concurrent runs would fork the ratchet; the lock prevents this.
- **Never copy the state to a second machine.** Enroll a second token instead.
- **`serial` is frozen at enrollment.** Every OTP re-derives
  `kma = sha256_128(pin + ";" + serial + "/" + dataAppli + "/" + alea)`. The serial is
  captured once (raw `/etc/machine-id`, trailing newline included, matching the app's
  Linux branch) and replayed from `state.json` forever. It is never re-read at OTP time.
- **Don't loop it.** Generating codes within 225s / 585s / 900s of the previous three
  trips the `bIsEarly` path and escalates to option B2/Bp, which ratchets `k` as well as
  `j`. Confirmed in testing: three codes in ~15s put the token straight into Bp.
  `tb-otp status` shows whether you are currently in that window.
- **The PIN on disk collapses the second factor** to "something the machine has". Inherent
  to headless 2FA. This is why it should be a *separate, independently revocable* token
  from the one on your phone/desktop.

## Tests

```sh
node test/shim.test.js                      # XHR shim vs a real local server
node test/offline-harness.js <fixture.json> # read-only; never generates a code
```

The harness runs against a *copy* of an existing credential and hard-fails on any write
attempt, so it cannot advance a live token's ratchet.

## Vendored code

`vendor/` holds `neon-lib-js` and `iw-commons-js` (inWebo, private registry) and their
dependencies. This code is proprietary and it is not on public npm.

**It is not in this repository, and you must not redistribute it.** Each user extracts it
from their own licensed copy of Authenticator 6 with `scripts/extract-vendor.sh`. The
script resolves the dependency set by trial, so it also works if a later version of the
application changes that set.

Do not replace these packages with newer ones. The versions are the ones the application
ships, and the server API is tested against them.
