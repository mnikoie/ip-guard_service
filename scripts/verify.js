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

const installServiceSource = fs.readFileSync(path.join(root, 'install-service.js'), 'utf8');
for (const detail of ['Seyed Mohammad Ali Nikoei', '+98 913 267 5400', 'm.nikoie2005@gmail.com']) {
  if (!installServiceSource.includes(detail)) throw new Error(`install-service.js is missing author detail: ${detail}`);
}

const dependencyRemovalSource = fs.readFileSync(path.join(root, '0-uninstall-dependencies.bat'), 'utf8');
if (!dependencyRemovalSource.includes('sc delete "%IPGUARD_SERVICE%"')) {
  throw new Error('Dependency removal must remove the Windows service when requested.');
}

const serviceRemovalSource = fs.readFileSync(path.join(root, '3-stop-and-uninstall-service.bat'), 'utf8');
if (!serviceRemovalSource.includes('sc delete ipguardservice.exe')) {
  throw new Error('Service removal must use the native Windows service deletion command.');
}

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
