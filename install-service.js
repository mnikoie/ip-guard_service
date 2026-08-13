/**
 * Installs index.js as a real Windows Service using node-windows.
 * Run this once with administrator privileges:  node install-service.js
 * After install, manage it from services.msc as "IPGuardService".
 */
const { Service } = require('node-windows');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// node-windows incorrectly treats a leftover local daemon folder as proof that
// the Windows service exists. Moving the project can therefore cause a false
// "already installed" result. The Service Control Manager is authoritative.
const serviceId = 'ipguardservice.exe';
const daemonDirectory = path.join(__dirname, 'daemon');
const expectedExecutable = path.join(daemonDirectory, serviceId);

function serviceExists() {
  try {
    execFileSync('sc.exe', ['query', serviceId], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function installedExecutablePath() {
  try {
    const output = execFileSync('sc.exe', ['qc', serviceId], { encoding: 'utf8' });
    const match = output.match(/BINARY_PATH_NAME\s*:\s*"?([^"\r\n]+?\.exe)"?(?:\s|$)/i);
    return match ? path.resolve(match[1].trim()) : null;
  } catch {
    return null;
  }
}

function wait(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function removeExistingService() {
  console.log('Removing the service registration from its previous location...');
  try { execFileSync('sc.exe', ['stop', serviceId], { stdio: 'ignore' }); } catch { }
  wait(1200);
  execFileSync('sc.exe', ['delete', serviceId], { stdio: 'inherit' });
  for (let attempt = 0; attempt < 10 && serviceExists(); attempt += 1) wait(500);
  if (serviceExists()) throw new Error('Windows is still deleting the previous IP Guard service. Wait a few seconds, then try again.');
}

const currentServiceExists = serviceExists();
const registeredExecutable = installedExecutablePath();
const expectedPath = path.resolve(expectedExecutable).toLowerCase();
if (currentServiceExists && registeredExecutable && registeredExecutable.toLowerCase() !== expectedPath) {
  removeExistingService();
}

if (!serviceExists() && fs.existsSync(daemonDirectory)) {
  console.log('Removing stale local service files left after moving the project...');
  fs.rmSync(daemonDirectory, { recursive: true, force: true });
}

const svc = new Service({
  name: 'IPGuardService',
  description: 'IP Guard Service — fail-closed public-IP guard. Author: Seyed Mohammad Ali Nikoei; Mobile: +98 913 267 5400; Email: m.nikoie2005@gmail.com',
  script: path.join(__dirname, 'index.js'),
  nodeOptions: [],
  workingDirectory: __dirname,
});

svc.on('install', () => {
  console.log('Service installed. Starting...');
  svc.start();
});

svc.on('alreadyinstalled', () => {
  console.log('Service is already installed at this project location. Use Restart service after changing config or code.');
});

svc.on('error', (error) => {
  console.error(`Service installation error: ${error.message || error}`);
  process.exitCode = 1;
});

svc.install();
