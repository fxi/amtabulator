#!/usr/bin/env node

import { readFileSync, writeFileSync, existsSync, unlinkSync } from "fs";
import { spawnSync, execSync } from "child_process";
import yaml from "js-yaml";

class VersionSyncer {
  constructor() {
    this.version = null;
    this.tempRScript = "temp-version-update.R";
    this.packageFile = "./package.json";
    this.descriptionFile = "DESCRIPTION";
    this.yamlFile = "inst/htmlwidgets/amtabulator.yaml";
    this.yamlDepName = "amtabulator";
  }

  run() {
    try {
      this.readVersionFromPackage();
      this.updateRDescription();
      this.updateYamlFile();
      this.commitChanges();
      this.log(`✓ Synced version to ${this.version}`);
    } catch (err) {
      this.error(err.message);
      process.exit(1);
    } finally {
      this.cleanup();
    }
  }

  readVersionFromPackage() {
    if (!existsSync(this.packageFile)) {
      throw new Error("package.json not found.");
    }
    const pkg = JSON.parse(readFileSync(this.packageFile));
    if (!pkg.version) throw new Error("No version field in package.json");
    this.version = pkg.version;
  }

  updateRDescription() {
    const scriptContent = `
      library(desc)
      desc <- desc::desc(file = "${this.descriptionFile}")
      desc$set_version("${this.version}")
      desc$write()
    `;
    writeFileSync(this.tempRScript, scriptContent);
    const result = spawnSync("Rscript", [this.tempRScript], {
      stdio: "inherit",
    });
    if (result.status !== 0) {
      throw new Error("R script failed to update DESCRIPTION");
    }
  }

  updateYamlFile() {
    if (!existsSync(this.yamlFile)) {
      throw new Error(`YAML file not found at ${this.yamlFile}`);
    }
    const raw = readFileSync(this.yamlFile, "utf8");
    const parsed = yaml.load(raw);

    if (!Array.isArray(parsed.dependencies)) {
      throw new Error("Invalid or missing dependencies in YAML");
    }

    const dep = parsed.dependencies.find((d) => d.name === this.yamlDepName);
    if (!dep) {
      throw new Error(`Dependency "${this.yamlDepName}" not found in YAML`);
    }

    dep.version = this.version;

    const newYaml = yaml.dump(parsed, { lineWidth: 1000 });
    writeFileSync(this.yamlFile, newYaml);
  }

  commitChanges() {
    try {
      execSync(`git add ${this.descriptionFile} ${this.yamlFile}`);
      const diffCheck = execSync('git diff --cached --quiet || echo "changed"')
        .toString()
        .trim();
      if (diffCheck === "changed") {
        execSync(
          `git commit -m "chore(release): bump version to ${this.version}"`
        );
      } else {
        this.log("✓ No changes to commit");
      }
    } catch (err) {
      this.warn("Git commit skipped or failed:", err.message);
    }
  }

  cleanup() {
    try {
      unlinkSync(this.tempRScript);
    } catch {}
  }

  log(...args) {
    console.log("›", ...args);
  }

  warn(...args) {
    console.warn("⚠️ ", ...args);
  }

  error(...args) {
    console.error("✗", ...args);
  }
}

new VersionSyncer().run();

