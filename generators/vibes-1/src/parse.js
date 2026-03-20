import { literal, nothing, or, optional, sequence, rand } from './operations.js';

/**
 * Recursively parses a JSON5-decoded definition object into a generator factory.
 */
export function parseDefinition(def) {
  switch (def.op) {
    case 'literal':
      return literal(def.value);

    case 'nothing':
      return nothing();

    case 'or':
      return or(def.choices.map(parseDefinition));

    case 'optional': {
      const delegate = def.delegate
        ? parseDefinition(def.delegate)
        : literal(def.value);
      return optional({
        delegate,
        emptyFirst: def.emptyFirst,
      });
    }

    case 'sequence':
      return sequence(def.children.map(parseDefinition));

    case 'rand': {
      const min = def.min ?? 1;
      const max = def.max ?? undefined; // undefined → defaults to min inside rand()
      return rand(def.chars, min, max);
    }

    default:
      throw new Error(`Unknown operation: "${def.op}"`);
  }
}
