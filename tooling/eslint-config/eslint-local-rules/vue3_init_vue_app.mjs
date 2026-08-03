// Flags app-bootstrap `new Vue(...)` roots and (where mechanical) rewrites
// them to the dual-runtime `initVueApp(...)` helper
// (app/assets/javascripts/lib/utils/vue3compat/init_vue_app.js).
//
// On the Vue 3 lanes, `new Vue({ el, render })` runs through @vue/compat's
// deprecated global-mount API (GLOBAL_MOUNT) and its legacy render-function
// emulation (RENDER_FUNCTION census). `initVueApp` is exactly the same
// `new Vue` call on Vue 2 — production behavior is unchanged — and a
// `createApp`-based mount with identical DOM semantics on Vue 3.
//
// A site is auto-fixable only when the conversion is a pure syntax move:
//
// - the argument is a plain object whose keys are a subset of
//   { el, name, provide, store, router, apolloProvider, pinia, render },
//   with both `el` and `render` present, and
// - `render` takes a single parameter and only returns `h(Component)` or
//   `h(Component, { props: ... })` where Component is a plain identifier
//   or member chain, and
// - none of the moved expressions rely on `this` or on the render parameter,
//   and no comments would be dropped by the rewrite.
//
// Everything else (event buses, `$mount()` chains, template/components
// roots, renders with children or Vue 2 data objects, options like `data`
// or lifecycle hooks) is reported without a fix and needs a manual pass.
// See scripts/frontend/codemods/vue3_init_vue_app.mjs for the batch codemod
// built on top of this rule.

const HELPER_SOURCE = '~/lib/utils/vue3compat/init_vue_app';
const HELPER_NAME = 'initVueApp';

const PASSTHROUGH_KEYS = new Set([
  'el',
  'name',
  'provide',
  'store',
  'router',
  'apolloProvider',
  'pinia',
]);

function getPropertyKeyName(property) {
  if (property.computed) {
    return null;
  }
  if (property.key.type === 'Identifier') {
    return property.key.name;
  }
  if (property.key.type === 'Literal' && typeof property.key.value === 'string') {
    return property.key.value;
  }
  return null;
}

function resolveVariable(scope, name) {
  let currentScope = scope;
  while (currentScope) {
    const variable = currentScope.set.get(name);
    if (variable) {
      return variable;
    }
    currentScope = currentScope.upper;
  }
  return null;
}

function isVueDefaultImport(variable) {
  const def = variable?.defs[0];
  return (
    def?.type === 'ImportBinding' &&
    def.node.type === 'ImportDefaultSpecifier' &&
    def.parent.source.value === 'vue'
  );
}

function containsThisExpression(root) {
  const queue = [root];
  while (queue.length > 0) {
    const node = queue.pop();
    if (!node || typeof node !== 'object') {
      continue;
    }
    if (Array.isArray(node)) {
      queue.push(...node);

      continue;
    }
    if (typeof node.type !== 'string') {
      continue;
    }
    if (node.type === 'ThisExpression') {
      return true;
    }
    Object.entries(node).forEach(([key, value]) => {
      if (key !== 'parent' && value && typeof value === 'object') {
        queue.push(value);
      }
    });
  }
  return false;
}

// Component references must be plain identifier/member chains so that
// moving them from render time to init time cannot change evaluation.
function isStaticReference(node) {
  if (node.type === 'Identifier') {
    return true;
  }
  if (node.type === 'MemberExpression' && !node.computed) {
    return isStaticReference(node.object);
  }
  return false;
}

// Extracts { componentNode, propsNode } from a render function that is
// exactly `(h) => h(Component)` / `(h) => h(Component, { props })`
// (arrow, function expression or object method; `return` form included).
function analyzeRender(renderFn) {
  if (
    !renderFn ||
    !['FunctionExpression', 'ArrowFunctionExpression'].includes(renderFn.type) ||
    renderFn.async ||
    renderFn.generator ||
    renderFn.params.length !== 1 ||
    renderFn.params[0].type !== 'Identifier'
  ) {
    return null;
  }

  let call = null;
  if (renderFn.body.type !== 'BlockStatement') {
    call = renderFn.body;
  } else if (renderFn.body.body.length === 1 && renderFn.body.body[0].type === 'ReturnStatement') {
    call = renderFn.body.body[0].argument;
  }

  if (
    !call ||
    call.type !== 'CallExpression' ||
    call.callee.type !== 'Identifier' ||
    call.callee.name !== renderFn.params[0].name ||
    call.arguments.length < 1 ||
    call.arguments.length > 2 ||
    call.arguments.some((argument) => argument.type === 'SpreadElement')
  ) {
    return null;
  }

  const [componentNode, dataNode] = call.arguments;
  if (!isStaticReference(componentNode)) {
    return null;
  }

  let propsNode = null;
  if (dataNode) {
    if (dataNode.type !== 'ObjectExpression') {
      return null;
    }
    for (const property of dataNode.properties) {
      if (property.type !== 'Property' || getPropertyKeyName(property) !== 'props') {
        return null;
      }
      propsNode = property.value;
    }
  }

  if (containsThisExpression(call)) {
    return null;
  }

  return { call, componentNode, propsNode };
}

export const vue3InitVueApp = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'Bootstrap Vue apps through the dual-runtime initVueApp helper instead of `new Vue(...)`',
    },
    fixable: 'code',
    schema: [],
    messages: {
      useInitVueApp:
        'Bootstrap this app with initVueApp(...) from {{helperSource}} instead of `new Vue(...)` so the Vue 3 runtime avoids the legacy global-mount API.',
      useInitVueAppManual:
        'This `new Vue(...)` cannot be converted mechanically; migrate it to initVueApp(...) from {{helperSource}} (or an appropriate helper) manually.',
      removeUnusedVueImport: 'The `Vue` default import is unused after the initVueApp conversion.',
    },
  },

  create(context) {
    const { sourceCode } = context;

    let vueImportDeclaration = null;
    let helperImportPresent = false;

    function findHelperConflict(scope) {
      const variable = resolveVariable(scope, HELPER_NAME);
      if (!variable) {
        return false;
      }
      const def = variable.defs[0];
      return !(def?.type === 'ImportBinding' && def.parent.source.value === HELPER_SOURCE);
    }

    function commentsSurviveRewrite(objectArgument, keptRanges) {
      return sourceCode
        .getCommentsInside(objectArgument)
        .every((comment) =>
          keptRanges.some(([start, end]) => comment.range[0] >= start && comment.range[1] <= end),
        );
    }

    function renderOptionText(property, key, valueNode) {
      const valueText = sourceCode.getText(valueNode ?? property.value);
      if (valueText === key) {
        return key;
      }
      return `${key}: ${valueText}`;
    }

    return {
      ImportDeclaration(node) {
        if (
          node.source.value === 'vue' &&
          node.specifiers.some((specifier) => specifier.type === 'ImportDefaultSpecifier')
        ) {
          vueImportDeclaration = node;
        }
        if (
          node.source.value === HELPER_SOURCE &&
          node.specifiers.some(
            (specifier) =>
              specifier.type === 'ImportSpecifier' && specifier.imported.name === HELPER_NAME,
          )
        ) {
          helperImportPresent = true;
        }
      },

      NewExpression(node) {
        if (node.callee.type !== 'Identifier') {
          return;
        }
        const scope = sourceCode.getScope(node);
        const calleeVariable = resolveVariable(scope, node.callee.name);
        if (!calleeVariable || !isVueDefaultImport(calleeVariable)) {
          return;
        }

        const reportManual = () => {
          context.report({
            node,
            messageId: 'useInitVueAppManual',
            data: { helperSource: HELPER_SOURCE },
          });
        };

        const objectArgument = node.arguments[0];
        if (
          node.arguments.length !== 1 ||
          objectArgument.type !== 'ObjectExpression' ||
          // `.$mount()` chains and other member accesses need manual handling
          (node.parent.type === 'MemberExpression' && node.parent.object === node)
        ) {
          reportManual();
          return;
        }

        const properties = [];
        for (const property of objectArgument.properties) {
          const key = property.type === 'Property' ? getPropertyKeyName(property) : null;
          if (
            key === null ||
            property.kind !== 'init' ||
            (!PASSTHROUGH_KEYS.has(key) && key !== 'render')
          ) {
            reportManual();
            return;
          }
          properties.push({ property, key });
        }

        const keys = new Set(properties.map(({ key }) => key));
        if (!keys.has('el') || !keys.has('render') || keys.size !== properties.length) {
          reportManual();
          return;
        }

        const renderEntry = properties.find(({ key }) => key === 'render');
        const renderInfo = analyzeRender(renderEntry.property.value);
        if (!renderInfo) {
          reportManual();
          return;
        }

        // The render parameter must not be referenced by the moved
        // expressions (its only reference must be the `h(...)` callee).
        const renderScope = sourceCode.getScope(renderEntry.property.value.body);
        const paramVariable = resolveVariable(
          renderScope,
          renderEntry.property.value.params[0].name,
        );
        const paramReferences = paramVariable?.references ?? [];
        if (
          paramReferences.length !== 1 ||
          paramReferences[0].identifier !== renderInfo.call.callee
        ) {
          reportManual();
          return;
        }

        const passthroughEntries = properties.filter(({ key }) => key !== 'render');
        if (containsThisExpression(passthroughEntries.map(({ property }) => property))) {
          reportManual();
          return;
        }

        const keptRanges = [
          ...passthroughEntries.map(({ property }) => property.range),
          renderInfo.componentNode.range,
          ...(renderInfo.propsNode ? [renderInfo.propsNode.range] : []),
        ];
        if (!commentsSurviveRewrite(objectArgument, keptRanges) || findHelperConflict(scope)) {
          reportManual();
          return;
        }

        context.report({
          node,
          messageId: 'useInitVueApp',
          data: { helperSource: HELPER_SOURCE },
          *fix(fixer) {
            const parts = [];
            for (const { property, key } of properties) {
              if (key === 'render') {
                parts.push(renderOptionText(property, 'component', renderInfo.componentNode));
                if (renderInfo.propsNode) {
                  parts.push(renderOptionText(property, 'props', renderInfo.propsNode));
                }
              } else {
                parts.push(sourceCode.getText(property));
              }
            }
            yield fixer.replaceText(node, `${HELPER_NAME}({ ${parts.join(', ')} })`);
            if (!helperImportPresent && vueImportDeclaration) {
              yield fixer.insertTextAfter(
                vueImportDeclaration,
                `\nimport { ${HELPER_NAME} } from '${HELPER_SOURCE}';`,
              );
            }
          },
        });
      },

      'Program:exit': function programExit() {
        if (!vueImportDeclaration || !helperImportPresent) {
          return;
        }
        const moduleScope = sourceCode.getScope(vueImportDeclaration);
        const vueLocalName = vueImportDeclaration.specifiers.find(
          (specifier) => specifier.type === 'ImportDefaultSpecifier',
        ).local.name;
        const vueVariable = resolveVariable(moduleScope, vueLocalName);
        if (!vueVariable || !isVueDefaultImport(vueVariable) || vueVariable.references.length > 0) {
          return;
        }

        context.report({
          node: vueImportDeclaration,
          messageId: 'removeUnusedVueImport',
          fix(fixer) {
            if (vueImportDeclaration.specifiers.length === 1) {
              const [start, end] = vueImportDeclaration.range;
              const removedEnd = sourceCode.text[end] === '\n' ? end + 1 : end;
              return fixer.removeRange([start, removedEnd]);
            }
            // `import Vue, { something } from 'vue';` — drop the default only
            const defaultSpecifier = vueImportDeclaration.specifiers.find(
              (specifier) => specifier.type === 'ImportDefaultSpecifier',
            );
            const comma = sourceCode.getTokenAfter(defaultSpecifier);
            const afterComma = sourceCode.getTokenAfter(comma);
            return fixer.removeRange([defaultSpecifier.range[0], afterComma.range[0]]);
          },
        });
      },
    };
  },
};
