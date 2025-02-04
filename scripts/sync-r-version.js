#!/usr/bin/env node

import { readFileSync, writeFileSync, unlinkSync } from 'fs';
import { execSync } from 'child_process';

const TEMP_R_SCRIPT = 'temp-version-update.R';

try {
  // Get version from package.json
  const version = JSON.parse(readFileSync('./package.json')).version;
  
  // Create and run R script
  const rScript = `
    library(desc)
    desc <- desc::desc(file = "DESCRIPTION")
    desc$set_version("${version}")
    desc$write()
  `;
  
  writeFileSync(TEMP_R_SCRIPT, rScript);
  execSync('Rscript temp-version-update.R', { stdio: 'inherit' });
  
  // Commit changes
  execSync('git add DESCRIPTION');
  execSync('git commit -m "chore(release): bump version to ' + version + '"');
  
  console.log(`✓ R package version synced to ${version}`);
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
} finally {
  try { unlinkSync(TEMP_R_SCRIPT); } catch {}
}