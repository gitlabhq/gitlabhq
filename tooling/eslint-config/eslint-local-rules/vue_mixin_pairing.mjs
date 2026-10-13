import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';
import { getPropertyKeyName } from './utils/gl_slots_mixin_injection.mjs';
import {
  findOption,
  getComponentOptions,
  normalizeImportSource,
} from './utils/component_options.mjs';

export const MESSAGE_IDS = {
  missing: 'missing',
  unused: 'unused',
};

// Component options whose keys (or string entries) declare instance members.
const MEMBER_OPTIONS = ['props', 'computed', 'methods', 'inject'];

const mixinEntrySchema = {
  type: 'object',
  properties: {
    source: { type: 'string' },
    imported: { type: 'string' },
    localName: { type: 'string' },
    factory: { oneOf: [{ type: 'boolean' }, { type: 'string' }] },
    members: { type: 'array', items: { type: 'string' }, minItems: 1 },
    reportUnused: { type: 'boolean' },
  },
  required: ['source', 'imported', 'members'],
  additionalProperties: false,
};

/**
 * Text of a registration for `entry` bound as `localName`, for messages:
 * `glFeatureFlagsMixin()`, `Tracking.mixin()` or `GlToastMixin`.
 */
export function registrationText(entry, localName) {
  if (entry.factory === true) {
    return `${localName}()`;
  }
  if (typeof entry.factory === 'string') {
    return `${localName}.${entry.factory}()`;
  }
  return localName;
}

function collectKeys(node) {
  if (!node) {
    return [];
  }
  if (node.type === 'ArrayExpression') {
    return node.elements
      .filter((element) => element?.type === 'Literal' && typeof element.value === 'string')
      .map((element) => element.value);
  }
  if (node.type === 'ObjectExpression') {
    return node.properties.map((property) => getPropertyKeyName(property)).filter(Boolean);
  }
  return [];
}

function collectDataKeys(dataProperty) {
  const fn = dataProperty?.value;
  if (!fn || (fn.type !== 'FunctionExpression' && fn.type !== 'ArrowFunctionExpression')) {
    return [];
  }
  if (fn.body.type === 'ObjectExpression') {
    return collectKeys(fn.body);
  }
  const returned = fn.body.body?.find((statement) => statement.type === 'ReturnStatement');
  return collectKeys(returned?.argument);
}

/**
 * Members the component declares on its own, so a usage of one of them is
 * not evidence that a mixin supplying the same name is needed. `inject`
 * matters most: `inject: ['glFeatures']` is a valid stand-in for
 * `glFeatureFlagsMixin()`.
 */
function collectDeclaredMembers(optionsObject) {
  const declared = new Set();
  if (!optionsObject) {
    return declared;
  }
  MEMBER_OPTIONS.forEach((option) => {
    collectKeys(findOption(optionsObject, option)?.value).forEach((key) => declared.add(key));
  });
  collectDataKeys(findOption(optionsObject, 'data')).forEach((key) => declared.add(key));
  return declared;
}

/**
 * Keep every configured mixin registration paired with a usage of what it
 * supplies, in the same component file:
 *
 * - a file using one of the mixin's members (in the template, as
 *   `this.member`, or destructured from `this`) must register the mixin, or
 *   the member is undefined at runtime, possibly only on a branch no spec
 *   renders;
 * - a file registering the mixin without using any member carries dead
 *   weight, and for the `inject`-based flag mixins a misleading signal about
 *   what the component depends on.
 *
 * Mixins are identified by their import (`source` + `imported`), not by the
 * local name, so `glFeatureFlagMixin` and `glFeatureFlagsMixin` are the same
 * mixin. A registration is the local binding itself, a call of it
 * (`factory: true`), a call of one of its members (`factory: 'mixin'`), or a
 * module-scope `const` bound to one of those.
 *
 * A member the component declares itself under `props`, `computed`,
 * `methods`, `inject` or `data()` does not count as a usage of the mixin.
 *
 * The rule only sees same-file evidence: a mixin arriving through another
 * mixin or `extends`, or a member reached through `$options` or
 * `this[name]`, needs an `eslint-disable` with a comment.
 */
export const vueMixinPairing = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'require a configured mixin registration and a usage of its members to appear together in a component file',
    },
    schema: [
      {
        type: 'object',
        properties: {
          mixins: { type: 'array', items: mixinEntrySchema },
          // The unused half can be switched off globally or per entry while
          // existing unused registrations are still being cleaned up.
          reportUnused: { type: 'boolean' },
        },
        additionalProperties: false,
      },
    ],
    messages: {
      [MESSAGE_IDS.missing]:
        "'{{member}}' is used but '{{registration}}' from '{{source}}' is not registered in this file. Import it and add it to the component `mixins`, or '{{member}}' is undefined at runtime.",
      [MESSAGE_IDS.unused]:
        "'{{registration}}' from '{{source}}' is registered but none of {{members}} is used in this file. Remove the mixin.",
    },
  },
  create(context) {
    const { sourceCode } = context;
    const entries = context.options[0]?.mixins ?? [];

    const imports = [];
    const usages = [];
    let optionsObject = null;
    let finalized = false;

    const moduleScope = () =>
      sourceCode.scopeManager.scopes.find((scope) => scope.type === 'module') ?? null;

    const variableFor = (name) => moduleScope()?.set.get(name) ?? null;

    const importBinding = (entry) => {
      const wanted = normalizeImportSource(entry.source, context.filename);
      for (const declaration of imports) {
        if (normalizeImportSource(declaration.source.value, context.filename) !== wanted) {
          continue;
        }
        const specifier = declaration.specifiers.find((candidate) =>
          entry.imported === 'default'
            ? candidate.type === 'ImportDefaultSpecifier'
            : candidate.type === 'ImportSpecifier' && candidate.imported.name === entry.imported,
        );
        if (specifier) {
          return specifier.local.name;
        }
      }
      return null;
    };

    const isRegistration = (node, entry, localName) => {
      if (!node) {
        return false;
      }
      if (node.type === 'CallExpression') {
        const { callee } = node;
        if (entry.factory === true) {
          return callee.type === 'Identifier' && callee.name === localName;
        }
        return (
          typeof entry.factory === 'string' &&
          callee.type === 'MemberExpression' &&
          !callee.computed &&
          callee.object.type === 'Identifier' &&
          callee.object.name === localName &&
          callee.property.name === entry.factory
        );
      }
      return node.type === 'Identifier' && !entry.factory && node.name === localName;
    };

    // Resolves `mixins: [trackingMixin]` through a module-scope
    // `const trackingMixin = InternalEvents.mixin();`.
    const aliasInit = (node) => {
      if (node?.type !== 'Identifier') {
        return null;
      }
      const declarator = variableFor(node.name)?.defs[0]?.node;
      return declarator?.type === 'VariableDeclarator' ? declarator.init : null;
    };

    const findRegistration = (mixinsArray, entry, localName) =>
      mixinsArray.elements.find(
        (element) =>
          isRegistration(element, entry, localName) ||
          isRegistration(aliasInit(element), entry, localName),
      ) ?? null;

    const reportMissing = ({ entry, localName, entryUsages }) => {
      const registration = registrationText(entry, localName ?? entry.localName ?? entry.imported);
      entryUsages.forEach((usage) => {
        context.report({
          node: usage.node,
          messageId: MESSAGE_IDS.missing,
          data: { member: usage.name, registration, source: entry.source },
        });
      });
    };

    const reportUnused = ({ entry, localName, registration }) => {
      context.report({
        node: registration,
        messageId: MESSAGE_IDS.unused,
        data: {
          registration: registrationText(entry, localName),
          source: entry.source,
          members: entry.members.map((member) => `'${member}'`).join(', '),
        },
      });
    };

    const finalize = () => {
      if (finalized) {
        return;
      }
      finalized = true;

      const declared = collectDeclaredMembers(optionsObject);
      const mixinsProperty = findOption(optionsObject, 'mixins');
      const mixinsArray =
        mixinsProperty?.value.type === 'ArrayExpression' ? mixinsProperty.value : null;

      const resolved = entries.map((entry) => {
        const localName = importBinding(entry);
        const registration =
          localName && mixinsArray ? findRegistration(mixinsArray, entry, localName) : null;
        return { entry, localName, registration };
      });

      // Two entries can supply the same member (the same mixin reachable
      // from two import paths, say); a usage is only missing its mixin when
      // none of them is registered.
      const supplied = new Set(
        resolved.flatMap(({ entry, registration }) => (registration ? entry.members : [])),
      );

      resolved.forEach(({ entry, localName, registration }) => {
        const entryUsages = usages.filter(
          (usage) =>
            entry.members.includes(usage.name) &&
            !declared.has(usage.name) &&
            (registration || !supplied.has(usage.name)),
        );

        if (entryUsages.length > 0 && !registration) {
          reportMissing({ entry, localName, entryUsages });
        } else if (
          entryUsages.length === 0 &&
          registration &&
          (entry.reportUnused ?? context.options[0]?.reportUnused ?? true)
        ) {
          reportUnused({ entry, localName, registration });
        }
      });
    };

    return defineTemplateBodyVisitor(
      context,
      // Template traversal runs after the script's `Program:exit`, so by the
      // time the root element exits both passes have contributed.
      {
        VExpressionContainer: (node) => {
          node.references.forEach((reference) => {
            // `variable` is set for `v-for` aliases and slot props; only
            // unresolved references read from the component instance.
            if (!reference.variable) {
              usages.push({ name: reference.id.name, node: reference.id });
            }
          });
        },
        "VElement[parent.type!='VElement']:exit": finalize,
      },
      {
        ImportDeclaration: (node) => {
          imports.push(node);
        },
        ExportDefaultDeclaration: (node) => {
          optionsObject = getComponentOptions(node);
        },
        'MemberExpression[object.type="ThisExpression"][computed=false]': (node) => {
          usages.push({ name: node.property.name, node });
        },
        'VariableDeclarator[init.type="ThisExpression"] > ObjectPattern > Property': (node) => {
          const name = getPropertyKeyName(node);
          if (name) {
            usages.push({ name, node });
          }
        },
        'Program:exit': (node) => {
          if (!node.templateBody) {
            finalize();
          }
        },
      },
    );
  },
};
