/**
 * IP Guard Service
 *
 * The service is intentionally fail-closed: configured applications may run
 * only while a fresh public-IP lookup has positively identified a trusted
 * country. Lookup and process enforcement use independent timers so a user
 * cannot relaunch a protected application while the network is unsafe.
 */

'use strict';

const axios = require('axios');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const winston = require('winston');

const CONFIG_PATH = path.join(__dirname, 'config.json');
const EXE_NAME = /^[^\\/:*?"<>|\s]+\.exe$/i;

function readConfig() {
  let raw;
  try {
    raw = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  } catch (error) {
    throw new Error(`Cannot read config.json: ${error.message}`);
  }

  const requiredPositiveNumbers = ['checkIntervalMs', 'killIntervalMs', 'requestTimeoutMs'];
  for (const key of requiredPositiveNumbers) {
    if (!Number.isInteger(raw[key]) || raw[key] < 1) {
      throw new Error(`config.${key} must be a positive integer.`);
    }
  }
  if (!Array.isArray(raw.ipApiEndpoints) || raw.ipApiEndpoints.length === 0) {
    throw new Error('config.ipApiEndpoints must contain at least one URL.');
  }
  if (!Array.isArray(raw.trustedCountryCodes) || raw.trustedCountryCodes.length === 0) {
    throw new Error('config.trustedCountryCodes must contain at least one ISO country code.');
  }
  if (!Array.isArray(raw.processesToKill)) {
    throw new Error('config.processesToKill must be an array.');
  }
  if (typeof raw.logFile !== 'string' || raw.logFile.trim() === '') {
    throw new Error('config.logFile must be a non-empty path.');
  }
  if (raw.statusFile !== undefined && (typeof raw.statusFile !== 'string' || raw.statusFile.trim() === '')) {
    throw new Error('config.statusFile must be a non-empty path when provided.');
  }

  for (const endpoint of raw.ipApiEndpoints) {
    try {
      const parsed = new URL(endpoint);
      if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') throw new Error('unsupported protocol');
    } catch (_) {
      throw new Error(`Invalid HTTP(S) URL in ipApiEndpoints: ${endpoint}`);
    }
  }
  for (const countryCode of raw.trustedCountryCodes) {
    if (!/^[A-Za-z]{2}$/.test(String(countryCode).trim())) {
      throw new Error(`Invalid ISO country code in trustedCountryCodes: ${countryCode}`);
    }
  }

  const targets = [...new Set(raw.processesToKill.map((value) => String(value).trim()))];
  const invalidTarget = targets.find((value) => !EXE_NAME.test(value));
  if (invalidTarget) {
    throw new Error(`Invalid executable name in processesToKill: ${invalidTarget}`);
  }

  return {
    ...raw,
    processesToKill: targets,
    trustedCountryCodes: new Set(raw.trustedCountryCodes.map((code) => String(code).trim().toUpperCase())),
    logFile: raw.logFile.trim(),
    statusFile: raw.statusFile ? raw.statusFile.trim() : 'C:\\ProgramData\\IPGuardService\\status.json',
  };
}

const config = readConfig();
for (const directory of new Set([path.dirname(config.logFile), path.dirname(config.statusFile)])) {
  fs.mkdirSync(directory, { recursive: true });
}

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => `[${timestamp}] [${level.toUpperCase()}] ${message}`),
  ),
  transports: [
    new winston.transports.File({ filename: config.logFile }),
    new winston.transports.Console(),
  ],
});

// New agents are used for every request. This prevents a keep-alive socket
// attached to a removed VPN adapter from poisoning future checks.
function freshHttpAgent(url) {
  return url.startsWith('https:')
    ? new https.Agent({ keepAlive: false })
    : new http.Agent({ keepAlive: false });
}

function normalizeLookupResponse(data) {
  // ip-api.com
  if (data && data.status === 'success' && data.query && data.countryCode) {
    return { ip: String(data.query), countryCode: String(data.countryCode).toUpperCase() };
  }
  // ipapi.co
  if (data && data.ip && (data.country_code || data.country)) {
    return { ip: String(data.ip), countryCode: String(data.country_code || data.country).toUpperCase() };
  }
  throw new Error(data && data.reason ? String(data.reason) : 'invalid lookup response');
}

async function lookupPublicIP() {
  const errors = [];
  for (const url of config.ipApiEndpoints) {
    try {
      const response = await axios.get(url, {
        timeout: config.requestTimeoutMs,
        headers: { Connection: 'close', Accept: 'application/json' },
        httpAgent: freshHttpAgent(url),
        httpsAgent: freshHttpAgent(url),
        validateStatus: (status) => status >= 200 && status < 300,
      });
      return normalizeLookupResponse(response.data);
    } catch (error) {
      errors.push(`${url}: ${error.message}`);
    }
  }
  throw new Error(errors.join(' | '));
}

let state = 'UNSAFE';
let lastIP = null;
let lastCountryCode = null;
let lastReason = 'Service starting: no trusted lookup has completed yet.';
let consecutiveLookupFailures = 0;
let lookupInFlight = false;
let killPassInFlight = false;

function writeStatus() {
  const status = {
    state,
    ip: lastIP,
    countryCode: lastCountryCode,
    reason: lastReason,
    updatedAt: new Date().toISOString(),
  };
  const temporaryFile = `${config.statusFile}.${process.pid}.tmp`;
  try {
    fs.writeFileSync(temporaryFile, JSON.stringify(status), 'utf8');
    fs.renameSync(temporaryFile, config.statusFile);
  } catch (error) {
    try { fs.unlinkSync(temporaryFile); } catch (_) { /* nothing to clean */ }
    logger.error(`Could not write status file: ${error.message}`);
  }
}

function setState(nextState, details) {
  const changed = state !== nextState || lastIP !== details.ip || lastCountryCode !== details.countryCode || lastReason !== details.reason;
  state = nextState;
  lastIP = details.ip || null;
  lastCountryCode = details.countryCode || null;
  lastReason = details.reason;
  writeStatus();

  if (changed) {
    logger.warn(`STATE: ${state} | IP: ${lastIP || 'unknown'} | Country: ${lastCountryCode || 'unknown'} | ${lastReason}`);
  }
}

function taskkill(processName) {
  return new Promise((resolve) => {
    const child = spawn('taskkill.exe', ['/IM', processName, '/F', '/T'], {
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let output = '';
    child.stdout.on('data', (chunk) => { output += chunk.toString(); });
    child.stderr.on('data', (chunk) => { output += chunk.toString(); });
    child.on('error', (error) => resolve({ processName, killed: false, error }));
    child.on('close', (code) => resolve({ processName, killed: code === 0, output: output.trim(), code }));
  });
}

async function enforceUnsafeState() {
  if (state !== 'UNSAFE' || killPassInFlight || config.processesToKill.length === 0) return;
  killPassInFlight = true;
  try {
    const results = await Promise.all(config.processesToKill.map(taskkill));
    for (const result of results) {
      // taskkill returns a non-zero code when no matching process exists. That
      // condition is expected, and intentionally produces no error log.
      if (result.killed) logger.info(`KILLED: ${result.processName}`);
      else if (result.error) logger.error(`taskkill could not start for ${result.processName}: ${result.error.message}`);
    }
  } finally {
    killPassInFlight = false;
  }
}

async function checkIP() {
  if (lookupInFlight) return;
  lookupInFlight = true;
  try {
    const info = await lookupPublicIP();
    if (consecutiveLookupFailures > 0) {
      logger.info(`IP lookup recovered after ${consecutiveLookupFailures} failed attempt(s).`);
      consecutiveLookupFailures = 0;
    }

    if (config.trustedCountryCodes.has(info.countryCode)) {
      setState('TRUSTED', { ...info, reason: 'Country is on the trusted list.' });
    } else {
      setState('UNSAFE', { ...info, reason: 'Country is not on the trusted list.' });
      void enforceUnsafeState();
    }
  } catch (error) {
    consecutiveLookupFailures += 1;
    // Log the first failure only; continued failures are still fail-closed.
    if (consecutiveLookupFailures === 1) logger.error(`IP lookup failed: ${error.message}`);
    setState('UNSAFE', {
      ip: null,
      countryCode: null,
      reason: 'IP lookup failed; fail-closed protection is active.',
    });
    void enforceUnsafeState();
  } finally {
    lookupInFlight = false;
  }
}

writeStatus();
logger.info(`IP Guard started. Lookup every ${config.checkIntervalMs}ms; enforcement every ${config.killIntervalMs}ms.`);
void enforceUnsafeState();
void checkIP();
setInterval(() => { void checkIP(); }, config.checkIntervalMs);
setInterval(() => { void enforceUnsafeState(); }, config.killIntervalMs);
