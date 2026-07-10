import fs from 'fs';
import path from 'path';

const EXPORT_DIR = 'llm_export';
const OUTPUT_FILE = path.join(EXPORT_DIR, 'full_codebase.md');
const TREE_FILE = path.join(EXPORT_DIR, 'file_tree.txt');

// Directories to ignore
const IGNORE_DIRS = new Set(['.git', 'node_modules', '.dart_tool', 'build', '.agents', '.claude', 'llm_export', 'docs/_TO_DELETE']);
// File extensions to include in full code dump
const INCLUDE_EXTS = new Set(['.dart', '.md', '.json', '.yaml', '.arb', '.mjs', '.txt', '.html']);
// Specific files to exclude
const EXCLUDE_FILES = new Set(['package-lock.json', 'kana_strokes.json']);

if (!fs.existsSync(EXPORT_DIR)) {
  fs.mkdirSync(EXPORT_DIR);
}

function generateTree(dir, prefix = '') {
  let output = '';
  const files = fs.readdirSync(dir).sort();
  
  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    if (IGNORE_DIRS.has(file)) continue;
    
    const fullPath = path.join(dir, file);
    const isLast = i === files.length - 1;
    const stat = fs.statSync(fullPath);
    
    output += `${prefix}${isLast ? '└── ' : '├── '}${file}\n`;
    
    if (stat.isDirectory()) {
      output += generateTree(fullPath, prefix + (isLast ? '    ' : '│   '));
    }
  }
  return output;
}

function dumpCodebase(dir, basePath = '') {
  let output = '';
  const files = fs.readdirSync(dir).sort();
  
  for (const file of files) {
    if (IGNORE_DIRS.has(file)) continue;
    if (EXCLUDE_FILES.has(file)) continue;
    
    const fullPath = path.join(dir, file);
    const relPath = path.join(basePath, file);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      output += dumpCodebase(fullPath, relPath);
    } else {
      const ext = path.extname(file);
      if (INCLUDE_EXTS.has(ext) || file === 'Dockerfile') {
        const content = fs.readFileSync(fullPath, 'utf8');
        output += `\n\n## File: ${relPath}\n\n`;
        output += '```' + (ext.replace('.', '') || 'text') + '\n';
        output += content;
        output += '\n```\n';
      }
    }
  }
  return output;
}

console.log('Generating file tree...');
const tree = 'SENSEI/\n' + generateTree('.');
fs.writeFileSync(TREE_FILE, tree);

console.log('Gathering codebase content...');
const code = `# SENSEI (Bhasago) Codebase Dump\n\n${dumpCodebase('.')}`;
fs.writeFileSync(OUTPUT_FILE, code);

console.log(`\nExport complete! Files created in /${EXPORT_DIR}:`);
console.log(`- ${TREE_FILE} (Directory structure)`);
console.log(`- ${OUTPUT_FILE} (All source code and markdown)`);
