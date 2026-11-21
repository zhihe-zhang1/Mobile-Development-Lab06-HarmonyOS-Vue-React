// Check the local Node.js runtime before Vite starts.
// This script intentionally uses syntax supported by older Node.js versions.
var version = process.versions.node.split('.').map(Number);
var major = version[0];
var minor = version[1];
var supported = (major === 20 && minor >= 19) || major >= 22;
if (!supported) {
  console.error('\nCannot start Lab 06: Node.js ' + process.version + ' is too old.');
  console.error('Please install Node.js 22 LTS or 24 LTS from https://nodejs.org/');
  console.error('After installation, reopen the terminal and run: node -v');
  console.error('Then run: npm install && npm run dev\n');
  process.exit(1);
}
