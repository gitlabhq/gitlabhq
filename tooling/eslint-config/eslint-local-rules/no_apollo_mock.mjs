// Forbids stubbing Apollo via `mocks: { $apollo: ... }` in component tests.
//
// `mocks: { $apollo }` injects a hand-rolled fake of the Apollo plugin onto
// the Vue instance. It bypasses the real Apollo client, so queries, the
// cache, and error handling never run the way they do in production — tests
// pass while the component is broken. The pattern predates `createMockApollo`
// and is the single most common Apollo-testing mistake; new tests keep
// copying it from older specs.
//
// Use `createMockApollo` (or `createControlledMockApollo` for request-by-
// request control) and provide it through `apolloProvider` instead:
//
//   const mockApollo = createMockApollo([[query, handler]]);
//   mount(Component, { apolloProvider: mockApollo });
//
// Part of gitlab-org/plan-stage#477 (WS1, Guardrail 2).

const APOLLO_MOCK_KEY = '$apollo';
const MOCKS_KEY = 'mocks';

// Returns the static name of a non-computed property key, or null.
function staticKeyName(property) {
  if (property.computed) return null;
  const { key } = property;
  if (key.type === 'Identifier') return key.name;
  if (key.type === 'Literal') return String(key.value);
  return null;
}

export const noApolloMock = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Disallow mocking Apollo via `mocks: { $apollo }` in tests',
      recommended: true,
    },
    messages: {
      noApolloMock:
        'Do not stub Apollo with `mocks: { $apollo }`. It bypasses the real Apollo client, so the cache and query behavior never run as they do in production. ' +
        'Use `createMockApollo` (or `createControlledMockApollo`) and pass it via `apolloProvider` instead. See gitlab-org/plan-stage#477.',
    },
    schema: [],
  },
  create(context) {
    return {
      Property(node) {
        if (staticKeyName(node) !== APOLLO_MOCK_KEY) return;

        // The object literal that directly contains this `$apollo` property.
        const containingObject = node.parent;
        if (!containingObject || containingObject.type !== 'ObjectExpression') return;

        // That object must be the *value* of a `mocks:` property to flag,
        // i.e. `mocks: { $apollo: ... }`. This avoids false positives like
        // `mocks: { $route: { $apollo: ... } }` or unrelated `$apollo` keys.
        const owningProperty = containingObject.parent;
        if (
          owningProperty &&
          owningProperty.type === 'Property' &&
          owningProperty.value === containingObject &&
          staticKeyName(owningProperty) === MOCKS_KEY
        ) {
          context.report({ node, messageId: 'noApolloMock' });
        }
      },
    };
  },
};
