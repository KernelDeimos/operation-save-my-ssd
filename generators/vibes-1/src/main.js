import { readFileSync } from 'fs';
import { resolve } from 'path';
import { parseArgs } from 'util';
import JSON5 from 'json5';
import { parseDefinition } from './parse.js';

const { values } = parseArgs({
  options: {
    resume: { type: 'string', short: 'r', default: '0' },
    definition: { type: 'string', short: 'd', default: 'definition.json5' },
  },
});

const resumeAt = parseInt(values.resume, 10);
if (!Number.isFinite(resumeAt) || resumeAt < 0) {
  process.stderr.write(`Invalid --resume value: ${values.resume}\n`);
  process.exit(1);
}

const defPath = resolve(values.definition);
let defText;
try {
  defText = readFileSync(defPath, 'utf8');
} catch (err) {
  process.stderr.write(`Cannot read definition file "${defPath}": ${err.message}\n`);
  process.exit(1);
}

const def = JSON5.parse(defText);
const factory = parseDefinition(def);

let index = 0;
for (const value of factory()) {
  if (index < resumeAt) {
    index++;
    continue;
  }
  process.stdout.write(value + '\n');
  process.stderr.write(`${index}\t${value}\n`);
  index++;
}
