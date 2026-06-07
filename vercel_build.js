const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FLUTTER_VERSION = '3.41.2';
const FLUTTER_TARBALL = `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz`;

async function main() {
  const workDir = '/tmp/flutter';

  if (!fs.existsSync(path.join(workDir, 'flutter', 'bin', 'flutter'))) {
    console.log('Downloading Flutter...');
    execSync(`mkdir -p ${workDir} && cd ${workDir} && curl -fsSL ${FLUTTER_TARBALL} | tar xJ`, { stdio: 'inherit' });
  }

  const flutterBin = path.join(workDir, 'flutter', 'bin', 'flutter');
  execSync(`PATH=${flutterBin}:$PATH ${flutterBin} config --no-analytics`, { stdio: 'inherit' });
  execSync(`PATH=${flutterBin}:$PATH ${flutterBin} precache -d web`, { stdio: 'inherit' });
  execSync(`PATH=${flutterBin}:$PATH ${flutterBin} build web --release`, { stdio: 'inherit' });

  console.log('Build complete!');
}

main().catch(e => { console.error(e); process.exit(1); });