// Forbids importing the same module path through both `jest/` and
// `ee_else_ce_jest/` aliases in the same file.
//
// In EE, the two aliases resolve to different files
// (`spec/frontend/X` vs `ee/spec/frontend/X`), so the imports look
// distinct. In FOSS, `ee_else_ce_jest/X` falls back to `spec/frontend/X`,
// collapsing both imports onto the same resolved path. The
// `import/no-duplicates` rule then fires only in FOSS context — usually
// after merge to master, because the FOSS pipeline runs once per MR.
//
// To stay edition-safe, import every symbol you need from the
// `ee_else_ce_jest/` alias and re-export any CE-only symbols from the
// EE-side module:
//
//   // ee/spec/frontend/X/handlers.js
//   export { buildHandlers } from 'jest/X/handlers';
//
//   // spec/frontend/Y/server.js
//   import { buildHandlers, featureHandlers } from 'ee_else_ce_jest/X/handlers';
//
// See gitlab-org/gitlab!230984 for the original incident.

const ALIAS_JEST = 'jest';
const ALIAS_EE_ELSE_CE_JEST = 'ee_else_ce_jest';

function parseAlias(source) {
  const match = source.match(/^(jest|ee_else_ce_jest)\/(.+)$/);
  if (!match) return null;
  return { alias: match[1], modulePath: match[2] };
}

export const noMixedJestAliases = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Disallow importing the same module via both `jest/` and `ee_else_ce_jest/` aliases in the same file',
      recommended: true,
    },
    messages: {
      mixedAliases:
        'Do not import the same module ("{{ modulePath }}") through both `{{ aliasA }}/` and `{{ aliasB }}/`. ' +
        'In FOSS context these aliases resolve to the same file, which trips `import/no-duplicates`. ' +
        'Import every symbol from `ee_else_ce_jest/{{ modulePath }}` and re-export any CE-only symbols from the EE-side module instead. ' +
        'See gitlab-org/gitlab!230984.',
    },
    schema: [],
  },
  create(context) {
    // Map from modulePath -> { jest?: node, ee_else_ce_jest?: node }
    const seen = new Map();

    function record(node) {
      const parsed = parseAlias(node.source.value);
      if (!parsed) return;

      const entry = seen.get(parsed.modulePath) ?? {};
      // Only flag the *second* import of the same module path, which
      // is the one that creates the conflict.
      if (parsed.alias === ALIAS_JEST && entry[ALIAS_EE_ELSE_CE_JEST]) {
        context.report({
          node,
          messageId: 'mixedAliases',
          data: {
            modulePath: parsed.modulePath,
            aliasA: ALIAS_EE_ELSE_CE_JEST,
            aliasB: ALIAS_JEST,
          },
        });
      } else if (parsed.alias === ALIAS_EE_ELSE_CE_JEST && entry[ALIAS_JEST]) {
        context.report({
          node,
          messageId: 'mixedAliases',
          data: {
            modulePath: parsed.modulePath,
            aliasA: ALIAS_JEST,
            aliasB: ALIAS_EE_ELSE_CE_JEST,
          },
        });
      }

      entry[parsed.alias] = node;
      seen.set(parsed.modulePath, entry);
    }

    return {
      ImportDeclaration: record,
      ExportNamedDeclaration(node) {
        if (node.source) record(node);
      },
      ExportAllDeclaration(node) {
        if (node.source) record(node);
      },
    };
  },
};
