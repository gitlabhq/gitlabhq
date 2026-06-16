// Enforces the shape of a page entrypoint (`index.js` files under
// `{app,ee/app,jh/app}/assets/javascripts/pages/`). Webpack registers each
// one as its own entry chunk (see `config/webpack.helpers.js`), so a real
// entrypoint must:
//
//   1. Execute something at module scope, otherwise webpack loads it and
//      nothing observable happens (a "ghost entrypoint").
//   2. Not export anything, since nothing should import it.
//
const PURE_DECLARATION_TYPES = new Set([
  // Top-level `const x = doThing()` is treated as declarative.
  // Entrypoints express side effects as statements (calls, `new`, `if`), so
  // this is a strong signal with negligible false-positive risk.
  'VariableDeclaration',
  'FunctionDeclaration',
  'ClassDeclaration',
  'EmptyStatement',
]);

function isSideEffectStatement(node) {
  if (node.type === 'ImportDeclaration') {
    // A bare import (`import 'x';`) has no specifiers and exists purely to
    // execute the imported module.
    return node.specifiers.length === 0;
  }
  return !PURE_DECLARATION_TYPES.has(node.type);
}

export const pageEntrypointMustExecute = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Require page entrypoint files (index.js files under ' +
        'app/assets/javascripts/pages/) to execute at module scope and to not ' +
        'export anything. Page entrypoints are top-level execution scripts; ' +
        'anything they export is dead code, and a file that only declares ' +
        'imports/functions/classes is a "ghost entrypoint" that webpack loads ' +
        'but never runs.',
      category: 'Possible Errors',
      recommended: true,
    },
    schema: [],
    messages: {
      noExport:
        'Page entrypoints must not export anything. They are top-level execution entrypoints ' +
        'for a page; nothing imports them, so any exported symbol is dead code. Move the export ' +
        'to a regular module and invoke it at the top level of this file instead.',
      missingSideEffect:
        'Page entrypoints must contain at least one top-level side-effect statement ' +
        '(for example, an init call, `new SomeClass()`, or a top-level `if` block). ' +
        'This file only declares imports/functions/variables, so webpack will load it ' +
        'but nothing will run. Invoke the entrypoint at the top level, or move this ' +
        'module out of pages/ if it is not actually an entrypoint.',
    },
  },

  create(context) {
    function reportNoExport(node) {
      context.report({ node, messageId: 'noExport' });
    }

    return {
      ExportNamedDeclaration: reportNoExport,
      ExportDefaultDeclaration: reportNoExport,
      ExportAllDeclaration: reportNoExport,

      Program(node) {
        const hasSideEffect = node.body.some((n) => isSideEffectStatement(n));
        if (hasSideEffect) return;

        context.report({ node, messageId: 'missingSideEffect' });
      },
    };
  },
};
