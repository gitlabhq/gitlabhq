// Flags jest specs that rely on the VTU v1 "find upgrade": calling
// component-only wrapper APIs (`.vm`, `.props()`, `.setProps()`, `.setData()`,
// `.emitted()`, `.destroy()`, `.unmount()`) on the result of a string-selector
// `find()` / `findAll()` / `findByTestId()` / `findAllByTestId()` call.
//
// In VTU v1 (Vue 2 jest lane), `find('[data-testid="x"]')` returns a
// component wrapper when the matched element is a component root. VTU v2
// (Vue 3 jest lane) returns a DOMWrapper which has none of the component
// APIs; the vue-test-utils-compat shim currently emulates the v1 behavior
// via its WRAPPER_FIND_BY_CSS_SELECTOR_RETURNS_COMPONENTS flag. To let us
// delete that shim, specs must use the explicit component finders instead:
//
//   wrapper.find('[data-testid="x"]').vm         // bad
//   wrapper.findComponent('[data-testid="x"]').vm // good
//
// The rule detects three shapes, pragmatically (no cross-function dataflow):
// - direct chains: `wrapper.find('.foo').vm`
// - single-assignment variables: `const el = wrapper.find('.foo'); el.props()`
// - finder functions (the dominant repo idiom):
//   `const findFoo = () => wrapper.find('.foo');` ... `findFoo().vm`
//
// Most reports are auto-fixable (`--fix`) by swapping the finder method:
// find -> findComponent, findAll -> findAllComponents,
// findByTestId -> findComponentByTestId,
// findAllByTestId -> findAllComponentsByTestId.
// Sites that mix component-only APIs with DOM-value APIs
// (setValue/setChecked/setSelected) on the same result are reported without
// a fix and need manual attention. See
// scripts/frontend/codemods/vue3_find_component_upgrade.mjs for the batch
// codemod built on top of this rule.

const FIND_METHOD_REPLACEMENTS = {
  find: 'findComponent',
  findAll: 'findAllComponents',
  findByTestId: 'findComponentByTestId',
  findAllByTestId: 'findAllComponentsByTestId',
};

const ALL_VARIANTS = new Set(['findAll', 'findAllByTestId']);

// VueWrapper-only APIs in VTU v2 (DOMWrapper lacks them).
const COMPONENT_ONLY_APIS = new Set([
  'vm',
  'props',
  'setProps',
  'setData',
  'emitted',
  'destroy',
  'unmount',
]);

// APIs that must keep DOM semantics once the compat shim is gone. Mixing
// them with component-only APIs on the same find() result cannot be fixed
// by a mechanical method swap.
const DOM_VALUE_APIS = new Set(['setValue', 'setChecked', 'setSelected']);

function isStringSelector(arg) {
  if (!arg) {
    return false;
  }
  if (arg.type === 'Literal') {
    return typeof arg.value === 'string';
  }
  return arg.type === 'TemplateLiteral';
}

// A selector like 'a' or 'button' with no attribute/class/structure parts.
// `findAll('<tag>')` typically matches a heterogeneous mix of component
// roots and plain elements, so swapping it for `findAllComponents` changes
// the result set (length, indexes) and cannot be auto-fixed.
function isBareTagSelector(arg) {
  const text =
    arg.type === 'Literal' ? arg.value : arg.quasis.map((quasi) => quasi.value.cooked).join('');
  return /^[a-zA-Z][a-zA-Z0-9-]*$/.test(text.trim());
}

function isEligibleFindCall(node) {
  const { callee } = node;
  if (callee?.type !== 'MemberExpression' || callee.computed) {
    return false;
  }
  if (callee.property.type !== 'Identifier') {
    return false;
  }

  const method = callee.property.name;
  if (!(method in FIND_METHOD_REPLACEMENTS)) {
    return false;
  }

  if (method === 'find' || method === 'findAll') {
    return node.arguments.length === 1 && isStringSelector(node.arguments[0]);
  }

  // findByTestId / findAllByTestId always build a string selector.
  return node.arguments.length >= 1;
}

/**
 * Classifies how the wrapper (or wrapper array) produced by `exprNode` is
 * used by its parent expression.
 *
 * @returns {'component'|'dom'|null}
 */
function classifyResultUsage(exprNode, isAllVariant) {
  const { parent } = exprNode;

  if (
    parent?.type !== 'MemberExpression' ||
    parent.object !== exprNode ||
    parent.computed ||
    parent.property.type !== 'Identifier'
  ) {
    return null;
  }

  const memberName = parent.property.name;

  if (isAllVariant) {
    // `findAll(...).at(n).<api>`
    if (
      memberName === 'at' &&
      parent.parent?.type === 'CallExpression' &&
      parent.parent.callee === parent
    ) {
      return classifyResultUsage(parent.parent, false);
    }
    return null;
  }

  if (COMPONENT_ONLY_APIS.has(memberName)) {
    return 'component';
  }
  if (DOM_VALUE_APIS.has(memberName)) {
    return 'dom';
  }
  return null;
}

export const vue3FindComponentUpgrade = {
  meta: {
    type: 'problem',
    fixable: 'code',
    docs: {
      description:
        'Disallow component-only wrapper APIs on string-selector find()/findAll() results (VTU v1 find-upgrade reliance)',
      recommended: true,
    },
    messages: {
      findComponentUpgrade:
        'Component-only wrapper API used on a string-selector `{{ method }}()` result. ' +
        'This relies on VTU v1 semantics that only a compat shim provides in the Vue 3 jest lane. ' +
        'Use `{{ replacement }}()` instead.',
      mixedFindUpgrade:
        'This `{{ method }}()` result is used with both component-only APIs and DOM value APIs ' +
        '(setValue/setChecked/setSelected), so it cannot be mechanically replaced with ' +
        '`{{ replacement }}()`. Split it into separate DOM and component finders.',
      bareTagFindAllUpgrade:
        'Component-only wrapper API used on a bare tag-name `{{ method }}()` result. ' +
        '`{{ replacement }}()` would only return component-rooted matches, changing the ' +
        'result set. Use a component or data-testid selector instead.',
      parameterizedFindUpgrade:
        'Component-only wrapper API used on the result of a parameterized `{{ method }}()` ' +
        'helper. Each call site may target a different kind of node, so this cannot be ' +
        'mechanically replaced with `{{ replacement }}()`. Split component call sites into ' +
        'dedicated `{{ replacement }}()` helpers.',
    },
    schema: [],
  },
  create(context) {
    const { sourceCode } = context;
    const findCalls = [];

    function resolveAssignedVariable(callNode) {
      const { parent } = callNode;

      // const el = wrapper.find('.foo');
      if (parent?.type === 'VariableDeclarator' && parent.init === callNode) {
        if (parent.id.type !== 'Identifier') {
          return null;
        }
        const variable = sourceCode
          .getDeclaredVariables(parent)
          .find((v) => v.name === parent.id.name);
        return variable ? { variable, isFinder: false } : null;
      }

      // el = wrapper.find('.foo'); (single write)
      if (
        parent?.type === 'AssignmentExpression' &&
        parent.right === callNode &&
        parent.operator === '=' &&
        parent.left.type === 'Identifier'
      ) {
        const scope = sourceCode.getScope(parent.left);
        const reference = scope.references.find((r) => r.identifier === parent.left);
        const variable = reference?.resolved;
        return variable ? { variable, isFinder: false } : null;
      }

      // const findFoo = () => wrapper.find('.foo');
      if (
        parent?.type === 'ArrowFunctionExpression' &&
        parent.body === callNode &&
        parent.parent?.type === 'VariableDeclarator' &&
        parent.parent.init === parent &&
        parent.parent.id.type === 'Identifier'
      ) {
        const declarator = parent.parent;
        const variable = sourceCode
          .getDeclaredVariables(declarator)
          .find((v) => v.name === declarator.id.name);
        // Parameterized helpers are not auto-fixable: each call site may
        // resolve to a different selector (and thus a different kind of
        // node), so one component-only usage does not prove the swap is
        // safe for the other call sites.
        return variable
          ? { variable, isFinder: true, isParameterized: parent.params.length > 0 }
          : null;
      }

      return null;
    }

    function classifyVariableUsages({ variable, isFinder }, isAllVariant) {
      // Only track variables assigned exactly once so the value is
      // unambiguous (const, or let assigned in a single place).
      const writes = variable.references.filter((r) => r.isWrite());
      if (writes.length !== 1) {
        return { hasComponentUsage: false, hasDomUsage: false };
      }

      let hasComponentUsage = false;
      let hasDomUsage = false;

      variable.references.forEach((reference) => {
        if (reference.isWrite()) {
          return;
        }

        const { identifier } = reference;
        let resultNode = identifier;
        if (isFinder) {
          if (
            identifier.parent?.type !== 'CallExpression' ||
            identifier.parent.callee !== identifier
          ) {
            return;
          }
          resultNode = identifier.parent;
        }

        const usage = classifyResultUsage(resultNode, isAllVariant);
        if (usage === 'component') {
          hasComponentUsage = true;
        } else if (usage === 'dom') {
          hasDomUsage = true;
        }
      });

      return { hasComponentUsage, hasDomUsage };
    }

    function checkFindCall(node) {
      const method = node.callee.property.name;
      const replacement = FIND_METHOD_REPLACEMENTS[method];
      const isAllVariant = ALL_VARIANTS.has(method);
      const isBareTagFindAll = method === 'findAll' && isBareTagSelector(node.arguments[0]);

      const report = (messageId, withFix) => {
        context.report({
          node: node.callee.property,
          messageId,
          data: { method, replacement },
          fix: withFix ? (fixer) => fixer.replaceText(node.callee.property, replacement) : null,
        });
      };

      // Direct chain: wrapper.find('.foo').vm
      if (node.parent?.type === 'MemberExpression' && node.parent.object === node) {
        if (classifyResultUsage(node, isAllVariant) === 'component') {
          if (isBareTagFindAll) {
            report('bareTagFindAllUpgrade', false);
          } else {
            report('findComponentUpgrade', true);
          }
        }
        return;
      }

      const assigned = resolveAssignedVariable(node);
      if (!assigned) {
        return;
      }

      const { hasComponentUsage, hasDomUsage } = classifyVariableUsages(assigned, isAllVariant);
      if (!hasComponentUsage) {
        return;
      }

      if (isBareTagFindAll) {
        report('bareTagFindAllUpgrade', false);
      } else if (assigned.isParameterized) {
        report('parameterizedFindUpgrade', false);
      } else if (hasDomUsage) {
        report('mixedFindUpgrade', false);
      } else {
        report('findComponentUpgrade', true);
      }
    }

    return {
      CallExpression(node) {
        if (isEligibleFindCall(node)) {
          findCalls.push(node);
        }
      },
      // Defer processing: scope references appearing after a find call do
      // not have `parent` links until the whole file has been traversed.
      'Program:exit': function processFindCalls() {
        findCalls.forEach((findCall) => checkFindCall(findCall));
      },
    };
  },
};
