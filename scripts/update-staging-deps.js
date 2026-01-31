#!/usr/bin/env node
/**
 * Updates jupyterlab/staging/package.json to use linkedPackages
 * for local packages (same approach as dev_mode).
 */

const fs = require('fs');
const path = require('path');

const stagingPkgPath = path.join(
  __dirname,
  '../jupyterlab/staging/package.json'
);
const packagesDir = path.join(__dirname, '../packages');

// Read staging package.json
const stagingPkg = JSON.parse(fs.readFileSync(stagingPkgPath, 'utf8'));

// Get list of local packages
const linkedPackages = {};
const packageDirs = fs.readdirSync(packagesDir).filter(dir => {
  const pkgJsonPath = path.join(packagesDir, dir, 'package.json');
  return fs.existsSync(pkgJsonPath) && dir !== 'external';
});

for (const dir of packageDirs) {
  const pkgJsonPath = path.join(packagesDir, dir, 'package.json');
  const pkgJson = JSON.parse(fs.readFileSync(pkgJsonPath, 'utf8'));
  // Use relative path like dev_mode does
  linkedPackages[pkgJson.name] = `../../packages/${dir}`;
}

console.log(`Found ${Object.keys(linkedPackages).length} local packages`);

// Revert any file: paths in dependencies back to npm versions
// by checking what the original version was (from resolutions)
const originalVersions = {
  // These should match the alpha versions
};

// For now, just ensure linkedPackages is set correctly
// The dependencies should use npm versions, linkedPackages overrides for dev
let revertedDeps = 0;
for (const [name, value] of Object.entries(stagingPkg.dependencies || {})) {
  if (typeof value === 'string' && value.startsWith('file:')) {
    // Revert to the alpha version
    stagingPkg.dependencies[name] = '~4.6.0-alpha.2';
    revertedDeps++;
  }
}
console.log(`Reverted ${revertedDeps} dependencies from file: paths`);

let revertedRes = 0;
for (const [name, value] of Object.entries(stagingPkg.resolutions || {})) {
  if (typeof value === 'string' && value.startsWith('file:')) {
    // Revert to the alpha version
    stagingPkg.resolutions[name] = '~4.6.0-alpha.2';
    revertedRes++;
  }
}
console.log(`Reverted ${revertedRes} resolutions from file: paths`);

// Set linkedPackages
stagingPkg.jupyterlab.linkedPackages = linkedPackages;
console.log(`Set ${Object.keys(linkedPackages).length} linkedPackages`);

// Write back
fs.writeFileSync(stagingPkgPath, JSON.stringify(stagingPkg, null, 2) + '\n');
console.log('Updated staging/package.json');
