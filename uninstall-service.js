const { Service } = require('node-windows');
const path = require('path');

const svc = new Service({
  name: 'IPGuardService',
  script: path.join(__dirname, 'index.js'),
});

svc.on('uninstall', () => {
  console.log('Service uninstalled.');
});

svc.on('alreadyuninstalled', () => {
  console.log('Service is not installed.');
});

svc.on('error', (error) => {
  console.error(`Service uninstall error: ${error.message || error}`);
  process.exitCode = 1;
});

svc.uninstall();
