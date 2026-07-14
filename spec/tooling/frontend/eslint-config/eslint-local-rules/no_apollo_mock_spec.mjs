import { RuleTester } from 'eslint';
import { noApolloMock } from '../../../../../tooling/eslint-config/eslint-local-rules/no_apollo_mock.mjs';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
});

ruleTester.run('no-apollo-mock', noApolloMock, {
  valid: [
    // Recommended pattern: createMockApollo provided via apolloProvider.
    {
      code: [
        'const mockApollo = createMockApollo(handlers);',
        'mount(Component, { apolloProvider: mockApollo });',
      ].join('\n'),
    },
    // `mocks` without `$apollo` is fine.
    {
      code: 'mount(Component, { mocks: { $router: { push: jest.fn() } } });',
    },
    // `$apollo` nested under `$route` (not directly under `mocks`) must not flag.
    {
      code: 'mount(Component, { mocks: { $route: { params: {}, $apollo: { query: jest.fn() } } } });',
    },
    // `$apollo` as a plain variable / property unrelated to a `mocks` object.
    {
      code: 'const config = { $apollo: { mutate: jest.fn() } };',
    },
  ],

  invalid: [
    // Nested-object form: mocks: { $apollo: { ... } }
    {
      code: [
        'mount(Component, {',
        '  mocks: {',
        '    $apollo: {',
        '      mutate: jest.fn(),',
        '      queries: { issuable: { loading: false } },',
        '    },',
        '  },',
        '});',
      ].join('\n'),
      errors: [{ messageId: 'noApolloMock' }],
    },
    // Shorthand form: mocks: { $apollo }
    {
      code: ['const $apollo = { mutate: jest.fn() };', 'mount(Component, { mocks: { $apollo } });'].join(
        '\n',
      ),
      errors: [{ messageId: 'noApolloMock' }],
    },
  ],
});
