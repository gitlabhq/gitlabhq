import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

export const MISSING_MIXIN_MESSAGE =
  '$toast is used but GlToastMixin is not registered in this file. Import it from @gitlab/ui and add it to the component `mixins`, or `this.$toast` is undefined unless some unrelated bundle happens to have installed GlToastPlugin.';

export const UNUSED_MIXIN_MESSAGE =
  'GlToastMixin is registered but $toast is never used in this file. Remove the mixin.';

export const ROOT_TOAST_MESSAGE =
  '$root.$toast reads the toast off the app root, which only works while some bundle installs GlToastPlugin globally. Use showToast from ~/vue_shared/plugins/global_toast. GlToastMixin is not a drop-in replacement here: it parents the toaster to this component, so a toast shown as this component goes away disappears with it.';

export const MANUAL_FIX_MESSAGE =
  '$toast is used but GlToastMixin cannot be added automatically here. Register GlToastMixin manually, or use showToast from ~/vue_shared/plugins/global_toast.';

const MIXIN_NAME = 'GlToastMixin';
const MIXIN_SOURCE = '@gitlab/ui';
const IMPORT_STATEMENT = `import { ${MIXIN_NAME} } from '${MIXIN_SOURCE}';`;

// Component options that `vue/order-in-components` requires above `mixins`.
const PROPERTIES_ABOVE_MIXINS = ['name', 'components', 'directives', 'filters', 'extends'];

/**
 * Keep `$toast` usage and the `GlToastMixin` registration together in the file
 * that needs them.
 *
 * `Vue.use(GlToastPlugin)` mutates the shared `Vue` constructor, so a component
 * calling `this.$toast` works as long as *some* bundle on the page installed
 * the plugin — historically `super_sidebar_bundle.js`, which installs it for
 * its own nav pin toasts and is loaded everywhere. Vue 3 apps do not share
 * that state, so the dependency has to be declared where it is used.
 *
 * The rule is bidirectional, so the declaration cannot drift from the usage:
 * a file using `$toast` must register the mixin, and a file registering the
 * mixin must use `$toast`.
 *
 * `$root.$toast` is reported without a fix. It breaks once the global installs
 * are gone, because the app root no longer carries the mixin. The mixin is not a
 * drop-in replacement: `@gitlab/ui` parents the toaster instance to the
 * component that shows the toast, so a locally declared mixin ties the toast's
 * lifetime to that component, while a `$root` read outlives it. `showToast` from
 * `~/vue_shared/plugins/global_toast` holds a Vue instance that outlives every
 * component; which one a call site wants depends on whether it survives its own
 * unmount.
 *
 * Fixes are minimal and do not reformat. Where the file already has
 * a named `@gitlab/ui` import the mixin joins it, so no duplicate statement is
 * produced; only a file importing nothing named from that module gets an import
 * of its own, which `import/order` then places. Neither fix can reflow a line
 * that outgrows Prettier's print width, because ESLint fixes splice text ranges
 * and Prettier is not wired in as a rule here. Batch-fix with
 * `yarn lint:eslint:fix` over the app directories, then run Prettier across the
 * files it touched; whatever eslint still reports afterwards needs a human.
 *
 * The rule only sees same-file evidence: a mixin arriving indirectly (through
 * another mixin or `extends`) needs an `eslint-disable` with a comment.
 */
export const glToastMixinRule = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'require $toast usage and the glToastMixin registration to appear together in a component file',
    },
    fixable: 'code',
    schema: [],
  },
  create(context) {
    const { sourceCode } = context;

    const usages = [];
    const rootUsages = [];
    const namedExportObjects = [];
    let mixinIdentifier = null;
    let mixinImport = null;
    let sourceImport = null;
    let optionsObject = null;
    let mixinsProperty = null;
    let lastImport = null;
    let finalized = false;

    const addImportFix = (fixer, fixes) => {
      if (mixinImport) {
        return;
      }

      // Most files already import something else from `@gitlab/ui`, so extend
      // that statement rather than adding a second import of the same module.
      const namedSpecifiers =
        sourceImport?.specifiers.filter((specifier) => specifier.type === 'ImportSpecifier') ?? [];

      if (namedSpecifiers.length > 0) {
        fixes.push(
          fixer.insertTextAfter(namedSpecifiers[namedSpecifiers.length - 1], `, ${MIXIN_NAME}`),
        );
      } else if (lastImport) {
        // No named specifiers to extend (default or namespace import, or no
        // `@gitlab/ui` import at all), so add a statement of our own.
        fixes.push(fixer.insertTextAfter(lastImport, `\n${IMPORT_STATEMENT}`));
      } else if (sourceCode.ast.body.length > 0) {
        fixes.push(fixer.insertTextBefore(sourceCode.ast.body[0], `${IMPORT_STATEMENT}\n\n`));
      }
    };

    // `vue/order-in-components` wants `mixins` below these, and it has no
    // autofix, so the inserted option has to land in the right place or the fix
    // leaves a lint failure behind on every file it touches.
    const insertMixinsOption = (fixer) => {
      const anchor = optionsObject.properties.findLast(
        (property) =>
          property.type === 'Property' && PROPERTIES_ABOVE_MIXINS.includes(property.key?.name),
      );

      if (!anchor) {
        const [firstProperty] = optionsObject.properties;
        const indent = ' '.repeat(firstProperty.loc.start.column);

        return fixer.insertTextBefore(firstProperty, `mixins: [${MIXIN_NAME}],\n${indent}`);
      }

      const indent = ' '.repeat(anchor.loc.start.column);
      const tokenAfter = sourceCode.getTokenAfter(anchor);

      return tokenAfter?.value === ','
        ? fixer.insertTextAfter(tokenAfter, `\n${indent}mixins: [${MIXIN_NAME}],`)
        : fixer.insertTextAfter(anchor, `,\n${indent}mixins: [${MIXIN_NAME}]`);
    };

    const addMixinFix = (fixer) => {
      const fixes = [];
      addImportFix(fixer, fixes);

      if (mixinsProperty) {
        const { elements } = mixinsProperty.value;

        if (elements.length > 0) {
          fixes.push(fixer.insertTextAfter(elements[elements.length - 1], `, ${MIXIN_NAME}`));
        } else {
          fixes.push(fixer.replaceText(mixinsProperty.value, `[${MIXIN_NAME}]`));
        }
      } else if (optionsObject.properties.length > 0) {
        fixes.push(insertMixinsOption(fixer));
      } else {
        fixes.push(fixer.replaceText(optionsObject, `{\n  mixins: [${MIXIN_NAME}],\n}`));
      }

      return fixes;
    };

    // Removes a node together with the whitespace separating it from the
    // previous token, so dropping an option or an import does not leave a
    // stranded blank line behind.
    const removeWithLeadingGap = (fixer, node, includeTrailingComma = false) => {
      const tokenBefore = sourceCode.getTokenBefore(node);
      const nextToken = sourceCode.getTokenAfter(node);
      const start = tokenBefore ? tokenBefore.range[1] : node.range[0];
      const end =
        includeTrailingComma && nextToken?.value === ',' ? nextToken.range[1] : node.range[1];

      return fixer.removeRange([start, end]);
    };

    const removeMixinFix = (fixer) => {
      const fixes = [];
      const { elements } = mixinsProperty.value;

      if (elements.length === 1) {
        // `mixins` only held this entry, so drop the whole option along with a
        // trailing comma if there is one.
        fixes.push(removeWithLeadingGap(fixer, mixinsProperty, true));
      } else {
        const index = elements.indexOf(mixinIdentifier);
        const isLast = index === elements.length - 1;
        const adjacentToken = isLast
          ? sourceCode.getTokenBefore(mixinIdentifier)
          : sourceCode.getTokenAfter(mixinIdentifier);
        const range = isLast
          ? [adjacentToken.range[0], mixinIdentifier.range[1]]
          : [mixinIdentifier.range[0], adjacentToken.range[1]];

        fixes.push(fixer.removeRange(range));
      }

      if (mixinImport) {
        if (mixinImport.specifiers.length === 1) {
          // Drop the whole statement plus the newline that followed it.
          const nextToken = sourceCode.getTokenAfter(mixinImport);
          const end = nextToken ? nextToken.range[0] : mixinImport.range[1];

          fixes.push(fixer.removeRange([mixinImport.range[0], end]));
        } else {
          // Shared with other `@gitlab/ui` imports, so drop just this
          // specifier. Take the comma on whichever side it sits, or a trailing
          // one is left behind when the mixin is last in the list.
          const specifier = mixinImport.specifiers.find(
            (candidate) => candidate.local.name === MIXIN_NAME,
          );
          const nextToken = sourceCode.getTokenAfter(specifier);
          const range =
            nextToken?.value === ','
              ? [specifier.range[0], nextToken.range[1]]
              : [sourceCode.getTokenBefore(specifier).range[0], specifier.range[1]];

          fixes.push(fixer.removeRange(range));
        }
      }

      return fixes;
    };

    const reportRootUsages = () => {
      rootUsages.forEach((node) => {
        // No fix: dropping the `$root` hop changes the toaster's lifetime, so the
        // replacement depends on whether the call site outlives its own unmount.
        context.report({ node, message: ROOT_TOAST_MESSAGE });
      });
    };

    // Resolved once both passes have run, rather than by selector, so the
    // default-export and named-export shapes are handled the same way and a
    // nested `mixins` (an inline component registration, say) cannot be
    // mistaken for the component's own.
    const resolveMixinRegistration = () => {
      optionsObject ??= namedExportObjects.length === 1 ? namedExportObjects[0] : null;

      mixinsProperty =
        optionsObject?.properties.find(
          (property) => property.type === 'Property' && property.key?.name === 'mixins',
        ) ?? null;

      if (mixinsProperty?.value.type === 'ArrayExpression') {
        mixinIdentifier =
          mixinsProperty.value.elements.find(
            (element) => element?.type === 'Identifier' && element.name === MIXIN_NAME,
          ) ?? null;
      }
    };

    const finalize = () => {
      if (finalized) {
        return;
      }
      finalized = true;

      resolveMixinRegistration();
      reportRootUsages();

      if (usages.length > 0 && !mixinIdentifier) {
        const canFix = Boolean(
          optionsObject && (!mixinsProperty || mixinsProperty.value.type === 'ArrayExpression'),
        );

        usages.forEach((node, index) => {
          context.report({
            node,
            message: canFix ? MISSING_MIXIN_MESSAGE : MANUAL_FIX_MESSAGE,
            // Every usage is reported so none is hidden, but the file only
            // needs one registration.
            fix: canFix && index === 0 ? addMixinFix : undefined,
          });
        });
      } else if (usages.length === 0 && mixinIdentifier) {
        context.report({
          node: mixinIdentifier,
          message: UNUSED_MIXIN_MESSAGE,
          fix: mixinsProperty?.value.type === 'ArrayExpression' ? removeMixinFix : undefined,
        });
      }
    };

    const captureOptionsObject = (node) => {
      const { declaration } = node;

      if (declaration.type === 'ObjectExpression') {
        optionsObject = declaration;
      } else if (declaration.type === 'CallExpression') {
        // e.g. `export default normalizeRender({ ... })`
        optionsObject =
          declaration.arguments.find((argument) => argument.type === 'ObjectExpression') ?? null;
      }
    };

    return defineTemplateBodyVisitor(
      context,
      // Template traversal runs after the script's `Program:exit`, so by the
      // time the root element exits both passes have contributed.
      {
        'MemberExpression[object.name="$root"][property.name="$toast"]': (node) => {
          rootUsages.push(node);
        },
        'Identifier[name="$toast"]': (node) => {
          // The `$toast` in `$root.$toast` matches this selector too; the
          // selector above records that form as a root usage.
          const isRootProperty =
            node.parent?.type === 'MemberExpression' &&
            node.parent.property === node &&
            node.parent.object?.name === '$root';

          if (!isRootProperty) {
            usages.push(node);
          }
        },
        "VElement[parent.type!='VElement']:exit": finalize,
      },
      {
        ImportDeclaration: (node) => {
          lastImport = node;

          if (node.source.value !== MIXIN_SOURCE) {
            return;
          }

          sourceImport ??= node;

          // `@gitlab/ui` is a barrel, so matching on the module alone would
          // mistake an unrelated import (GlButton, say) for the mixin's.
          const importsMixin = node.specifiers.some(
            (specifier) =>
              specifier.type === 'ImportSpecifier' && specifier.imported?.name === MIXIN_NAME,
          );

          if (importsMixin) {
            mixinImport = node;
          }
        },
        ExportDefaultDeclaration: captureOptionsObject,
        // Mixin modules commonly use a named export instead
        // (`export const fooMixin = { ... }`). Only trusted when it is
        // unambiguous: exactly one exported object literal and no default.
        'ExportNamedDeclaration > VariableDeclaration > VariableDeclarator > ObjectExpression': (
          node,
        ) => {
          namedExportObjects.push(node);
        },
        'MemberExpression[property.name="$toast"][computed=false]': (node) => {
          if (node.object.type === 'ThisExpression') {
            usages.push(node);
          } else if (
            node.object.type === 'MemberExpression' &&
            node.object.property?.name === '$root'
          ) {
            // A root read only. The mixin does not satisfy it, so counting it as
            // a usage would add a registration that nothing uses, which the
            // unused-mixin half then reports.
            rootUsages.push(node);
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
