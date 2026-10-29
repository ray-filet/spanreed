// Prepended to every journey by `spanreed-verify drive`. The line above defines SPANREED:
// { run, pid, bundle, home, config, files, evidence, journey }.
const fs = require("node:fs");
const path = require("node:path");

const homeNote = path.join(SPANREED.home, "Home.txt");
const configFile = path.join(SPANREED.config, "config");
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

function log(message) {
  const line = `${new Date().toISOString()} ${SPANREED.journey} ${message}`;
  fs.appendFileSync(path.join(SPANREED.evidence, "drive.log"), line + "\n");
  nodeRepl.write(line + "\n");
}

var app = await cua.getApp(SPANREED.bundle);

function state() {
  return app.getAXState({ emit: false });
}

// State lines look like "    47 text entry area (settable, string)".
function indexOf(text, re) {
  for (const line of text.split("\n")) {
    const match = /^\s*(\d+) (.*)$/.exec(line);
    if (match && re.test(match[2])) return match[1];
  }
  throw new Error(`no element matching ${re}`);
}

async function waitFor(re, ms = 10000) {
  for (const end = Date.now() + ms; Date.now() < end; await sleep(300)) {
    const text = await state();
    if (re.test(text)) return text;
  }
  throw new Error(`timed out waiting for ${re} in the focused window`);
}

async function waitForFile(file, predicate, ms = 5000) {
  let text = null;
  for (const end = Date.now() + ms; Date.now() < end; await sleep(200)) {
    text = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : null;
    if (text !== null && predicate(text)) return text;
  }
  throw new Error(`timed out waiting for ${file}; last contents: ${JSON.stringify(text)}`);
}

async function waitForExit(ms = 5000) {
  for (const end = Date.now() + ms; Date.now() < end; await sleep(200)) {
    try { process.kill(SPANREED.pid, 0); } catch { return; }
  }
  throw new Error(`Spanreed pid ${SPANREED.pid} still running after ${ms} ms`);
}

// Logs the user action before running it, so drive.log pairs each action with the snaps around it.
async function act(description, action) {
  log(`act: ${description}`);
  await action();
}

// Writes <name>.ax.txt, <name>.png, and copies of Home.txt and config into the evidence folder.
async function snap(name) {
  const { state: ax, screenshot } = await app.getAXStateAndScreenshot({ emit: false });
  fs.writeFileSync(path.join(SPANREED.evidence, `${name}.ax.txt`), ax);
  if (screenshot) fs.writeFileSync(path.join(SPANREED.evidence, `${name}.png`), screenshot);
  for (const [source, suffix] of [[homeNote, "home.txt"], [configFile, "config"]]) {
    if (fs.existsSync(source)) fs.copyFileSync(source, path.join(SPANREED.evidence, `${name}.${suffix}`));
  }
  log(`snap: ${name}`);
}

function pass(message) {
  log(`PASS ${message}`);
}
