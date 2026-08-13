/**
 * Installs index.js as a real Windows Service using node-windows.
 * Run this once with administrator privileges:  node install-service.js
 * After install, manage it from services.msc as "IPGuardService".
 */
const { Service } = require('node-windows');
const path = require('path');

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
  console.log('Service is already installed. Use 4-restart-service.bat after changing config or code.');
});

svc.on('error', (error) => {
  console.error(`Service installation error: ${error.message || error}`);
  process.exitCode = 1;
});

svc.install();
