import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

/**
 * @param {string} filePath
 * @returns {string}
 */
function sha256(filePath) {
  return 'sha256:' + createHash('sha256').update(readFileSync(filePath)).digest('hex');
}

/**
 * @param {string} dir
 * @returns {string[]}
 */
function findManifests(dir) {
  const results = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory() && entry.name !== 'scripts' && entry.name !== '.git') {
      results.push(...findManifests(fullPath));
    } else if (entry.name === 'manifest.json') {
      results.push(fullPath);
    }
  }
  return results;
}

const manifests = findManifests(ROOT);
let updated = 0;

for (const manifestPath of manifests) {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'));
  if (!manifest.files?.length) continue;

  let changed = false;

  for (const file of manifest.files) {
    const absPath = join(ROOT, file.src);
    try {
      const hash = sha256(absPath);
      if (file.hash !== hash) {
        file.hash = hash;
        changed = true;
      }
    } catch {
      console.warn(`[ ! ] Arquivo não encontrado: ${file.src}`);
    }
  }

  if (changed) {
    writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf-8');
    const rel = manifestPath.replace(ROOT + '/', '');
    console.log(`[ ✓ ] ${rel}`);
    updated++;
  }
}

console.log(`\n${updated} manifest(s) atualizado(s).`);
