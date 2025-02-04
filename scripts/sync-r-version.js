#!/usr/bin/env node

import { readFileSync, writeFileSync } from 'fs';
import { execSync } from 'child_process';

// Read package.json version
const packageJson = JSON.parse(readFileSync('./package.json', 'utf8'));
const version = packageJson.version;

// Create R script to update DESCRIPTION version
const rScript = `
library(desc)
desc <- desc::desc(file = "DESCRIPTION")
desc$set_version("${version}")
desc$write()
`;

try {
  // Write temporary R script
  writeFileSync('temp-version-update.R', rScript);
  
  // Execute R script
  execSync('Rscript temp-version-update.R', { stdio: 'inherit' });
  
  // Clean up
  execSync('rm temp-version-update.R');
  
  console.log(`✓ Successfully synchronized R package version to ${version}`);
  
  // Stage the DESCRIPTION file
  execSync('git add DESCRIPTION');
} catch (error) {
  console.error('Failed to sync R package version:', error);
  process.exit(1);
}
