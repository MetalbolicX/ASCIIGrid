import { spawnSync } from 'node:child_process';
import { readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const cliPath = join(__dirname, '../../dist/cli.mjs');

const runCli = (args, input) => {
  const tmpFile = `/tmp/asciigrid-test-${Date.now()}.json`;
  writeFileSync(tmpFile, input);
  try {
    const result = spawnSync('node', [cliPath, '--input', tmpFile, ...args.split(' ').filter(Boolean)], {
      encoding: 'utf8',
    });
    return { stdout: result.stdout, stderr: result.stderr, status: result.status };
  } finally {
    try { unlinkSync(tmpFile); } catch {}
  }
};

const runCliSimple = (args) => {
  const result = spawnSync('node', [cliPath, ...args.split(' ').filter(Boolean)], {
    encoding: 'utf8',
  });
  return result.stdout;
};

{
  console.log('Testing --help...');
  const out = runCliSimple('--help');
  assert(out.includes('Usage:'), 'help should include Usage');
  assert(out.includes('--input'), 'help should include --input');
  console.log('  PASS');
}

{
  console.log('Testing --version...');
  const out = runCliSimple('--version');
  assert(out.includes('ASCIIGrid'), 'version should include ASCIIGrid');
  assert(out.includes('1.0.0'), 'version should include 1.0.0');
  console.log('  PASS');
}

{
  console.log('Testing JSON matrix from stdin...');
  const { stdout } = runCli('', '[["Name","Age"],["Alice","30"],["Bob","25"]]');
  assert(stdout.includes('Name'), 'output should include Name');
  assert(stdout.includes('Alice'), 'output should include Alice');
  assert(stdout.includes('Age'), 'output should include Age');
  assert(stdout.includes('Bob'), 'output should include Bob');
  assert(stdout.includes('+---'), 'output should include borders');
  console.log('  PASS');
}

{
  console.log('Testing JSON array of objects...');
  const { stdout } = runCli('', '[{"name":"Alice","age":30},{"name":"Bob","age":25}]');
  assert(stdout.includes('name'), 'output should include name column');
  assert(stdout.includes('age'), 'output should include age column');
  assert(stdout.includes('Alice'), 'output should include Alice');
  assert(stdout.includes('Bob'), 'output should include Bob');
  console.log('  PASS');
}

{
  console.log('Testing NDJSON...');
  const { stdout } = runCli('--format ndjson', '{"name":"Alice","age":30}\n{"name":"Bob","age":25}\n');
  assert(stdout.includes('name'), 'output should include name');
  assert(stdout.includes('Alice'), 'output should include Alice');
  console.log('  PASS');
}

{
  console.log('Testing --title...');
  const { stdout } = runCli('--title Users', '[["Name","Age"],["Alice","30"]]');
  assert(stdout.includes('Users'), 'output should include title text');
  assert(stdout.includes('+---'), 'output should include border');
  console.log('  PASS');
}

{
  console.log('Testing --padding 2...');
  const { stdout } = runCli('--padding 2', '[["Name"],["Alice"]]');
  assert(stdout.includes('  Alice  '), 'padding 2 should wrap cell with double spaces');
  console.log('  PASS');
}

{
  console.log('Testing --no-header...');
  const { stdout } = runCli('--no-header', '[["Name","Age"],["Alice","30"]]');
  assert(stdout.length > 0, 'no-header should return non-empty output');
  const hasMiddleSep = stdout.includes('+---+---') && !stdout.includes('| Name ');
  assert(!hasMiddleSep, 'no-header should not show middle separator');
  console.log('  PASS');
}

{
  console.log('Testing --spreadsheet...');
  const { stdout } = runCli('--spreadsheet', '[["Name","Age"],["Alice","30"]]');
  assert(stdout.includes('| 0 |'), 'output should include row index 0');
  assert(stdout.includes('| 1 |'), 'output should include row index 1');
  assert(stdout.includes(' A '), 'output should include column letter A (with spaces)');
  assert(stdout.includes(' B '), 'output should include column letter B (with spaces)');
  console.log('  PASS');
}

{
  console.log('Testing --align...');
  const { stdout } = runCli('--align', '[["Item","Price"],["Apple",42],["Banana",7]]');
  assert(stdout.includes('Apple'), 'output should include Apple');
  assert(stdout.includes('  42'), 'price 42 should be right-aligned with spaces');
  console.log('  PASS');
}

{
  console.log('Testing --theme unicode...');
  const { stdout } = runCli('--theme unicode', '[["Name"],["Alice"]]');
  assert(stdout.includes('║'), 'output should contain Unicode wall');
  assert(stdout.includes('╔'), 'output should contain Unicode upper-left corner');
  assert(stdout.includes('╚'), 'output should contain Unicode lower-left corner');
  console.log('  PASS');
}

{
  console.log('Testing --rich...');
  const { stdout } = runCli('--rich', '[["value"],[30],[22.5],[true],[null]]');
  assert(stdout.includes('30'), 'output should contain integer 30');
  assert(stdout.includes('22.5'), 'output should contain float 22.5');
  assert(stdout.includes('true'), 'output should contain boolean true');
  console.log('  PASS');
}

{
  console.log('Testing --output writes to file...');
  const tmpOut = `/tmp/asciigrid-output-${Date.now()}.txt`;
  runCli(`--output ${tmpOut}`, '[["Name"],["Alice"]]');
  const content = readFileSync(tmpOut, 'utf8');
  assert(content.includes('Alice'), 'file output should contain Alice');
  assert(content.includes('+---'), 'file output should contain border');
  unlinkSync(tmpOut);
  console.log('  PASS');
}

{
  console.log('Testing invalid JSON exits with error...');
  const tmpFile = `/tmp/asciigrid-test-${Date.now()}.json`;
  writeFileSync(tmpFile, 'not valid json {');
  try {
    const result = spawnSync('node', [cliPath, '--input', tmpFile], { encoding: 'utf8' });
    assert(result.status === 2, 'invalid JSON should exit with code 2');
  } finally {
    try { unlinkSync(tmpFile); } catch {}
  }
  console.log('  PASS');
}

{
  console.log('Testing --theme oracle...');
  const { stdout } = runCli('--theme oracle', '[["Name"],["Alice"]]');
  assert(stdout.includes('Alice'), 'oracle output should contain Alice');
  console.log('  PASS');
}

{
  console.log('Testing invalid --theme exits with code 1...');
  const tmpFile = `/tmp/asciigrid-test-${Date.now()}.json`;
  writeFileSync(tmpFile, '[["Name"],["Alice"]]');
  try {
    const result = spawnSync('node', [cliPath, '--input', tmpFile, '--theme', 'invalid'], { encoding: 'utf8' });
    assert(result.status === 1, `invalid theme should exit with code 1, got ${result.status}`);
    assert(result.stderr.includes('Invalid theme'), 'stderr should mention Invalid theme');
  } finally {
    try { unlinkSync(tmpFile); } catch {}
  }
  console.log('  PASS');
}

{
  console.log('Testing invalid --format exits with code 1...');
  const tmpFile = `/tmp/asciigrid-test-${Date.now()}.json`;
  writeFileSync(tmpFile, '[["Name"],["Alice"]]');
  try {
    const result = spawnSync('node', [cliPath, '--input', tmpFile, '--format', 'csv'], { encoding: 'utf8' });
    assert(result.status === 1, `invalid format should exit with code 1, got ${result.status}`);
    assert(result.stderr.includes('Invalid format'), 'stderr should mention Invalid format');
  } finally {
    try { unlinkSync(tmpFile); } catch {}
  }
  console.log('  PASS');
}

console.log('\nAll CLI integration tests passed!');