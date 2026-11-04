/**
 * Static inventory of the Data API calls in the Flutter app (Dart,
 * supabase_flutter) and the Edge Functions (TypeScript, supabase-js):
 *
 *   tables     `.from('t')` chains: verbs (select, insert, update, upsert,
 *              delete), the selected columns and the columns filtered or
 *              ordered on (PostgREST turns those into SQL that reads them)
 *   rpcs       `.rpc('f')` / `rpc<T>('f')` names, both branches of a ternary
 *   realtime   tables watched with `onPostgresChanges` (Dart) or
 *              `.on('postgres_changes', { table })` (TypeScript)
 *
 * validate-sql.mjs compares the result with the privileges the migrations
 * grant. A call the scanner cannot read (a table or function name that is not
 * a string literal, an embedded resource in `select`) is reported as an error
 * rather than skipped, so the check never passes by accident.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const VERBS = new Set(['select', 'insert', 'update', 'upsert', 'delete']);
const FILTERS = new Set([
  'eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'like', 'ilike', 'is', 'isFilter', 'in', 'inFilter',
  'contains', 'containedBy', 'overlaps', 'rangeGt', 'rangeGte', 'rangeLt', 'rangeLte',
  'rangeAdjacent', 'textSearch', 'not', 'filter', 'order',
]);

/** Files under `root` with one of `extensions`, minus generated code and tests. */
export function listSources(root, extensions) {
  const files = [];
  const visit = (dir) => {
    for (const name of readdirSync(dir).sort()) {
      const path = join(dir, name);
      if (statSync(path).isDirectory()) {
        if (name !== 'generated' && name !== 'node_modules' && !name.startsWith('.')) visit(path);
      } else if (extensions.some((ext) => name.endsWith(ext)) && !/\.(g|test|freezed)\.\w+$/.test(name)) {
        files.push(path);
      }
    }
  };
  visit(root);
  return files;
}

/** Index just past the string literal that starts at `i` (', " or `). */
function skipString(src, i) {
  const quote = src[i];
  for (let j = i + 1; j < src.length; j++) {
    if (src[j] === '\\') j++;
    else if (src[j] === quote) return j + 1;
  }
  return src.length;
}

/** Index just past the bracket group that opens at `i`, skipping strings. */
function skipGroup(src, i) {
  const pairs = { '(': ')', '[': ']', '{': '}', '<': '>' };
  const stack = [pairs[src[i]]];
  for (let j = i + 1; j < src.length; j++) {
    const c = src[j];
    if (c === "'" || c === '"' || c === '`') {
      j = skipString(src, j) - 1;
    } else if (c === stack[stack.length - 1]) {
      stack.pop();
      if (stack.length === 0) return j + 1;
    } else if (c in pairs && (c !== '<' || stack[stack.length - 1] === '>')) {
      stack.push(pairs[c]);
    }
  }
  return src.length;
}

/** The method calls chained after `start`: [{ name, args }] for `.name<…>(args)…`. */
function chain(src, start) {
  const calls = [];
  let i = start;
  for (;;) {
    const m = /^\s*\.\s*([A-Za-z_]\w*)\s*/.exec(src.slice(i, i + 200));
    if (!m) break;
    let j = i + m[0].length;
    if (src[j] === '<') j = skipGroup(src, j);
    while (/\s/.test(src[j] ?? '')) j++;
    if (src[j] !== '(') break;
    const end = skipGroup(src, j);
    calls.push({ name: m[1], args: src.slice(j + 1, end - 1) });
    i = end;
  }
  return calls;
}

/** String literal contents in `text`. */
function literals(text) {
  return [...text.matchAll(/'([^'\\]*)'|"([^"\\]*)"/g)].map((m) => m[1] ?? m[2]);
}

/** The first top-level argument of an argument list. */
function firstArg(args) {
  for (let i = 0; i < args.length; i++) {
    const c = args[i];
    if (c === "'" || c === '"' || c === '`') i = skipString(args, i) - 1;
    else if (c === '(' || c === '[' || c === '{') i = skipGroup(args, i) - 1;
    else if (c === ',') return args.slice(0, i).trim();
  }
  return args.trim();
}

function lineOf(src, index) {
  return src.slice(0, index).split('\n').length;
}

/** Columns named by a PostgREST select list ('*' for all of them). */
function selectColumns(list, where, errors) {
  if (list === undefined || list.trim() === '' || list.trim() === '*') return ['*'];
  const columns = [];
  for (const raw of list.split(',')) {
    const item = raw.trim();
    if (item === '*') return ['*'];
    if (/[()!]/.test(item)) {
      errors.push(`${where}: embedded resource "${item}" is not checked; extend data-api-surface.mjs`);
      continue;
    }
    const column = item.replace(/^[A-Za-z_]\w*:/, '').replace(/::.*$/, '').replace(/->.*$/, '').trim();
    if (column) columns.push(column);
  }
  return columns;
}

/**
 * Scans `files` (paths relative to `base` in the report).
 * Returns { tables: [{ table, verbs, columns, filters, where }], rpcs: [{ name, where }],
 * realtime: [{ table, where }], errors: [string] }.
 */
export function scanDataApi(files, base, { dynamicRpcAllowed = [] } = {}) {
  const tables = [];
  const rpcs = [];
  const realtime = [];
  const errors = [];

  for (const file of files) {
    const src = readFileSync(file, 'utf8');
    const name = relative(base, file);

    for (const m of src.matchAll(/\.from\(\s*(['"])([A-Za-z_]\w*)\1\s*\)/g)) {
      const where = `${name}:${lineOf(src, m.index)}`;
      const usage = { table: m[2], verbs: new Set(), columns: new Set(), filters: new Set(), where };
      for (const call of chain(src, m.index + m[0].length)) {
        if (VERBS.has(call.name)) {
          usage.verbs.add(call.name);
          if (call.name === 'select') {
            for (const column of selectColumns(literals(firstArg(call.args))[0], where, errors)) {
              usage.columns.add(column);
            }
          }
          if (call.name === 'upsert') {
            const conflict = /onConflict\s*:\s*['"]([^'"]+)['"]/.exec(call.args);
            for (const column of conflict ? conflict[1].split(',') : []) usage.filters.add(column.trim());
          }
        } else if (FILTERS.has(call.name)) {
          const column = literals(firstArg(call.args))[0];
          if (column) usage.filters.add(column.replace(/->.*$/, ''));
        }
      }
      if (usage.verbs.size === 0) errors.push(`${where}: .from('${usage.table}') without select/insert/update/upsert/delete`);
      tables.push(usage);
    }

    for (const m of src.matchAll(/\brpc\s*(<[^()]*?>)?\s*\(/g)) {
      const where = `${name}:${lineOf(src, m.index)}`;
      const open = m.index + m[0].length - 1;
      const head = firstArg(src.slice(open + 1, skipGroup(src, open) - 1));
      const names = literals(head);
      if (names.length === 0) {
        if (!dynamicRpcAllowed.includes(name)) errors.push(`${where}: rpc() with a name that is not a string literal`);
        continue;
      }
      for (const fn of names) rpcs.push({ name: fn, where });
    }

    for (const m of src.matchAll(/\bonPostgresChanges\s*\(/g)) {
      const where = `${name}:${lineOf(src, m.index)}`;
      const open = m.index + m[0].length - 1;
      const args = src.slice(open + 1, skipGroup(src, open) - 1);
      const direct = /\btable\s*:\s*(['"])([A-Za-z_]\w*)\1/.exec(args);
      if (direct) {
        realtime.push({ table: direct[2], where });
        continue;
      }
      const variable = /\btable\s*:\s*([A-Za-z_]\w*)/.exec(args);
      const before = src.slice(Math.max(0, m.index - 800), m.index);
      const loop = variable &&
        new RegExp(`for\\s*\\(\\s*(?:final|var|const)?\\s*(?:\\w+\\s+)?${variable[1]}\\s+in\\s+(?:const\\s*)?\\[([^\\]]*)\\]`)
          .exec(before);
      const names = loop ? literals(loop[1]) : [];
      if (names.length === 0) errors.push(`${where}: cannot tell which table this Realtime subscription watches`);
      for (const table of names) realtime.push({ table, where });
    }

    for (const m of src.matchAll(/\.on\(\s*['"]postgres_changes['"]\s*,/g)) {
      const where = `${name}:${lineOf(src, m.index)}`;
      const direct = /\btable\s*:\s*(['"])([A-Za-z_]\w*)\1/.exec(src.slice(m.index, m.index + 400));
      if (direct) realtime.push({ table: direct[2], where });
      else errors.push(`${where}: cannot tell which table this Realtime subscription watches`);
    }
  }
  return { tables, rpcs, realtime, errors };
}

/**
 * The string keys of the map literal returned by the Dart function `fnName`
 * in `file` (used for the profile fields the app sends to `profiles`).
 */
export function returnedMapKeys(file, fnName) {
  const src = readFileSync(file, 'utf8');
  const def = new RegExp(`\\b${fnName}\\s*\\([^)]*\\)\\s*(?:async\\s*)?\\{`).exec(src);
  if (!def) return null;
  const body = src.slice(def.index + def[0].length - 1, skipGroup(src, def.index + def[0].length - 1));
  const ret = /\breturn\s*\{/.exec(body);
  if (!ret) return null;
  const open = ret.index + ret[0].length - 1;
  const map = body.slice(open + 1, skipGroup(body, open) - 1);
  // Top-level entries only: split on commas outside strings and brackets.
  const keys = [];
  let entry = 0;
  for (let i = 0; i <= map.length; i++) {
    const c = map[i];
    if (c === "'" || c === '"' || c === '`') i = skipString(map, i) - 1;
    else if (c === '(' || c === '[' || c === '{') i = skipGroup(map, i) - 1;
    else if (c === ',' || i === map.length) {
      const key = /^\s*'([a-z_][a-z0-9_]*)'\s*:/.exec(map.slice(entry, i));
      if (key) keys.push(key[1]);
      entry = i + 1;
    }
  }
  return keys;
}
