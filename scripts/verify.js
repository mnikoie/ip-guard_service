'use strict';

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const requiredFiles = [
  'index.js',
  'config.json',
  'config.example.json',
  'alert.ps1',
  'tray-manager.ps1',
  'tray-manager.cs',
  'build-tray-manager.ps1',
  'IP Guard Tray.exe',
  'install-tray-manager.bat',
  'uninstall-tray-manager.bat',
  '0-uninstall-dependencies.bat',
  'start-service.bat',
  'stop-service.bat',
  'assets/ip-guard-ai.ico',
  'assets/ip-guard-user.png',
  'scripts/convert-user-tray-icon.ps1',
  'docs/images/quick-start-fa.png',
  'docs/images/quick-start-en.png',
  'docs/ABOUT.md',
  'docs/ABOUT.fa.md',
  'install-overlay.bat',
  'README.md',
  'README.fa.md',
];

for (const file of requiredFiles) {
  if (!fs.existsSync(path.join(root, file))) throw new Error(`Required file is missing: ${file}`);
}

const requiredConfigKeys = [
  'checkIntervalMs',
  'killIntervalMs',
  'requestTimeoutMs',
  'ipApiEndpoints',
  'trustedCountryCodes',
  'processesToKill',
  'logFile',
  'statusFile',
];

for (const name of ['config.json', 'config.example.json']) {
  const config = JSON.parse(fs.readFileSync(path.join(root, name), 'utf8'));
  for (const key of requiredConfigKeys) {
    if (!(key in config)) throw new Error(`${name} is missing '${key}'.`);
  }
  if (!Array.isArray(config.ipApiEndpoints) || config.ipApiEndpoints.length === 0) {
    throw new Error(`${name} must define at least one lookup endpoint.`);
  }
  if (!Array.isArray(config.trustedCountryCodes) || config.trustedCountryCodes.length === 0) {
    throw new Error(`${name} must define at least one trusted country.`);
  }
}

console.log('Static project checks passed.');
