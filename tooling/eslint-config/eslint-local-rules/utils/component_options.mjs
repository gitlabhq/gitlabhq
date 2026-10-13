// Shared helpers for rules that inspect a Vue component's options object
// (`mixins`, `directives`). Used by `vue-mixin-pairing` and
// `vue-directive-pairing`.

import path from 'node:path';
import { getPropertyKeyName } from './gl_slots_mixin_injection.mjs';

/**
 * The options object of a component file's default export, for both
 * `export default { ... }` and `export default normalizeRender({ ... })`.
 */
export function getComponentOptions(exportDefaultNode) {
  const { declaration } = exportDefaultNode;

  if (declaration.type === 'ObjectExpression') {
    return declaration;
  }
  if (declaration.type === 'CallExpression') {
    return declaration.arguments.find((argument) => argument.type === 'ObjectExpression') ?? null;
  }
  return null;
}

export function findOption(optionsObject, name) {
  return (
    optionsObject?.properties.find((property) => getPropertyKeyName(property) === name) ?? null
  );
}

const JS_ROOT = /^.*\/app\/assets\/javascripts\//;

/**
 * Reduces an import source to a path under `app/assets/javascripts`, so
 * `~/vue_shared/mixins/timeago`, `ee_else_ce/vue_shared/mixins/timeago` and a
 * relative `../mixins/timeago` from a file in `vue_shared/components` all
 * compare equal. Package imports (`@gitlab/ui`) are returned as they are.
 */
export function normalizeImportSource(source, filename) {
  if (source.startsWith('~/')) {
    return source.slice(2);
  }
  if (source.startsWith('ee_else_ce/')) {
    return source.slice('ee_else_ce/'.length);
  }
  if (source.startsWith('.')) {
    const absolute = path.resolve(path.dirname(filename), source);
    return absolute.replace(JS_ROOT, '');
  }
  return source;
}

export function toKebabCase(name) {
  return name
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/_/g, '-')
    .toLowerCase();
}
