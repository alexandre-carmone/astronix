'use strict';
const fs = require('fs');

// Values lifted verbatim from Authenticator 6 v6.38.0.5319's own prod configuration
// (www bundle `neonConfiguration` literal + the `prod` entry of its environments table,
// plus the overrides applied in InweboServiceProvider.startInWeboLib for the Electron
// desktop platform). Changing any of these changes what the server sees.
const PROD = {
  serverUrl: 'https://ult-inwebo.com',   // NOT myinwebo.com -- that is the console URL
  macId: '0',
  dataAppli: 'shell',
  appVersion: '6.38.0',
  pushType: 'firebase',
  tokenApp: 'near',
  tokenPlatform: 'pc',
  deviceOS: 'linux',
  connectorAlias: '',
  kFactory:
    'a2f436dd91f7e1693079c0b41fcbc3235d1dcdd22d0cbceaf0bec8878f68503efe44d8a49142aa84' +
    'fceca8dd696462a5cdd5f75528cd6789cf098277faeef42d4c407a36e7d7e9e8cd1571bb13c9b7af' +
    '71c9d671f2b75270573ed6a19a10656503685873e811cec661515b31fe8ebfa58ba19b0124cdd690' +
    '47993e9d60562631',
  timeout: 30000,                        // app uses 5000; too tight for a cold CLI start
  isStorageSecured: true,                // MANDATORY -- see note below
};

// isStorageSecured=false makes CredentialService.save() strip keys.k/h/j/tRef before
// writing, and OfflineOtpService refuses outright with
// "UNSUPPORTED OPERATION: Offline OTP are not allowed with unsecured storage".
// It means "the caller is responsible for protecting this at rest", which we are: 0600.

/**
 * The app derives its serial on Linux from `cat /etc/machine-id` and -- unlike the
 * win32/darwin branches -- applies no .trim(), so the trailing newline is part of the
 * serial. readFileSync gives the identical string.
 *
 * This value is baked into every OTP: getKma() recomputes
 *   sha256_128(pin + ";" + serial + "/" + dataAppli + "/" + credential.keys.alea)
 * on each generation. If it ever changes, the derived key changes and the token is dead.
 * So we capture it once at enrollment and replay it from state.json forever after --
 * this function is only called during `enroll`.
 */
function readMachineSerial() {
  return fs.readFileSync('/etc/machine-id', 'utf8');
}

function buildConfig({ serial, dataAppli, storageSource }) {
  if (!serial) throw new Error('serial is required');
  return {
    serverUrl: PROD.serverUrl,
    storageUrl: null,
    macId: PROD.macId,
    serial,
    dataAppli: dataAppli || PROD.dataAppli,
    appVersion: PROD.appVersion,
    pushType: PROD.pushType,
    storageSource,
    logger: null,
    tokenApp: PROD.tokenApp,
    tokenPlatform: PROD.tokenPlatform,
    deviceOS: PROD.deviceOS,
    kFactory: PROD.kFactory,
    timeout: PROD.timeout,
    connectorAlias: PROD.connectorAlias,
    isStorageSecured: PROD.isStorageSecured,
  };
}

module.exports = { PROD, readMachineSerial, buildConfig };
