// Shared machinery for rules whose fixes introduce `glSlots()` calls into a
// component: injecting the `glSlotsMixin` import and registering it in the
// default export's `mixins` array. Used by `vue3-gl-slots` and
// `vue3-no-unconditional-slot-forwarding`.

export const MIXIN_NAME = 'glSlotsMixin';
export const MIXIN_SOURCE = '~/lib/utils/vue3compat/gl_slots_mixin';

export function getPropertyKeyName(property) {
  if (property.type !== 'Property' || property.computed) {
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

/**
 * A file's script can take the mixin injection only when its default export
 * is a plain object expression whose `mixins` option (if present) is an
 * array literal.
 */
export function canInjectMixin(exportObject) {
  if (!exportObject) {
    return false;
  }
  const mixinsProperty = exportObject.properties.find(
    (property) => getPropertyKeyName(property) === 'mixins',
  );
  if (mixinsProperty && mixinsProperty.value.type !== 'ArrayExpression') {
    return false;
  }
  // A spread before the mixins insertion point could redefine options; stay
  // conservative when the object contains spreads and no mixins array to
  // extend.
  if (!mixinsProperty && exportObject.properties.some((property) => property.type !== 'Property')) {
    return false;
  }
  return true;
}

export function buildInjectionFixes(fixer, { sourceCode, exportObject, lastImport, hasMixinImport }) {
  const fixes = [];

  if (!hasMixinImport) {
    const importText = `import { ${MIXIN_NAME} } from '${MIXIN_SOURCE}';`;
    if (lastImport) {
      fixes.push(fixer.insertTextAfter(lastImport, `\n${importText}`));
    } else {
      // No imports yet: insert before the whole `export default` (the
      // object expression itself starts after the `export default`
      // keywords).
      fixes.push(fixer.insertTextBefore(exportObject.parent, `${importText}\n`));
    }
  }

  const mixinsProperty = exportObject.properties.find(
    (property) => getPropertyKeyName(property) === 'mixins',
  );

  if (mixinsProperty) {
    const { elements } = mixinsProperty.value;
    const alreadyRegistered = elements.some(
      (element) => element?.type === 'Identifier' && element.name === MIXIN_NAME,
    );
    if (!alreadyRegistered) {
      const lastElement = elements[elements.length - 1];
      if (lastElement) {
        fixes.push(fixer.insertTextAfter(lastElement, `, ${MIXIN_NAME}`));
      } else {
        fixes.push(fixer.replaceTextRange(mixinsProperty.value.range, `[${MIXIN_NAME}]`));
      }
    }
  } else {
    // `mixins` sits below name/components/directives in the
    // vue/order-in-components convention, so anchor on the last one.
    const anchor = exportObject.properties.findLast((property) =>
      ['components', 'directives', 'name'].includes(getPropertyKeyName(property)),
    );
    const insertion = `mixins: [${MIXIN_NAME}],`;
    if (anchor) {
      fixes.push(fixer.insertTextAfter(anchor, `,\n  ${insertion}`));

      // The anchor's trailing comma (if any) now duplicates the one we
      // added; prettier cannot fix `,,`, so consume it.
      const nextToken = sourceCode.getTokenAfter(anchor);
      if (nextToken && nextToken.value === ',') {
        fixes.push(fixer.remove(nextToken));
      }
    } else if (exportObject.properties.length > 0) {
      fixes.push(fixer.insertTextBefore(exportObject.properties[0], `${insertion}\n  `));
    } else {
      fixes.push(fixer.replaceTextRange(exportObject.range, `{ ${insertion} }`));
    }
  }

  return fixes;
}
