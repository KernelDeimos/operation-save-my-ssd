/**
 * Each operation returns a "generator factory": a zero-argument function that,
 * when called, returns a fresh generator yielding strings.
 */

export function literal(value) {
  return function* () {
    yield value;
  };
}

export function nothing() {
  return function* () {
    yield '';
  };
}

/** Yields all values from each choice factory in order. */
export function or(choices) {
  return function* () {
    for (const choice of choices) {
      yield* choice();
    }
  };
}

/** Yields all values from the delegate factory, then one empty string. */
export function optional({
  delegate: delegateFactory,
  emptyFirst,
}) {
  return function* () {
    if ( emptyFirst ) {
      yield '';
      yield* delegateFactory();
    } else {
      yield* delegateFactory();
      yield '';
    }
  };
}

/**
 * Yields the string-concatenated cartesian product of all children's outputs.
 * Iterates children left-to-right: the rightmost child cycles fastest.
 */
export function sequence(children) {
  if (children.length === 0) {
    return function* () {
      yield '';
    };
  }
  return function* () {
    yield* combine(children, 0, '');
  };
}

function* combine(children, index, prefix) {
  if (index === children.length) {
    yield prefix;
    return;
  }
  for (const value of children[index]()) {
    yield* combine(children, index + 1, prefix + value);
  }
}

/**
 * Yields all strings of lengths [min, max] over the given charset,
 * in lexicographic order by charset position (shortest strings first).
 * Defaults: min=1, max=min.
 */
export function rand(chars, min = 1, max = undefined) {
  const lo = min;
  const hi = max ?? min;
  return function* () {
    for (let len = lo; len <= hi; len++) {
      yield* allStrings(chars, len);
    }
  };
}

function* allStrings(chars, len) {
  if (len === 0) {
    yield '';
    return;
  }
  for (const char of chars) {
    for (const suffix of allStrings(chars, len - 1)) {
      yield char + suffix;
    }
  }
}
