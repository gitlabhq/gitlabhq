import { RuleTester } from 'eslint';
import { noMixedJestAliases } from '../../../../../tooling/eslint-config/eslint-local-rules/no_mixed_jest_aliases.mjs';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
});

ruleTester.run('no-mixed-jest-aliases', noMixedJestAliases, {
  valid: [
    {
      code: "import { buildHandlers, featureHandlers } from 'ee_else_ce_jest/msw_integration/handlers';",
    },
    {
      code: "import { something } from 'jest/some/module';",
    },
    {
      code: [
        "import { a } from 'jest/module_a';",
        "import { b } from 'ee_else_ce_jest/module_b';",
      ].join('\n'),
    },
    {
      code: ["import { a } from 'jest/module';", "import { b } from 'jest/module';"].join('\n'),
    },
    {
      code: "export { buildHandlers } from 'jest/msw_integration/handlers';",
    },
    {
      code: ["import { a } from '~/utils';", "import { b } from 'ee_else_ce/utils';"].join('\n'),
    },
  ],

  invalid: [
    {
      code: [
        "import { buildHandlers } from 'jest/msw_integration/handlers';",
        "import { featureHandlers, restEndpoints } from 'ee_else_ce_jest/msw_integration/handlers';",
      ].join('\n'),
      errors: [{ messageId: 'mixedAliases' }],
    },
    {
      code: [
        "import { featureHandlers } from 'ee_else_ce_jest/msw_integration/handlers';",
        "import { buildHandlers } from 'jest/msw_integration/handlers';",
      ].join('\n'),
      errors: [{ messageId: 'mixedAliases' }],
    },
    {
      code: [
        "import 'jest/work_items/mock_data';",
        "import { workItem } from 'ee_else_ce_jest/work_items/mock_data';",
      ].join('\n'),
      errors: [{ messageId: 'mixedAliases' }],
    },
    {
      code: [
        "import { a } from 'ee_else_ce_jest/foo/bar';",
        "export { b } from 'jest/foo/bar';",
      ].join('\n'),
      errors: [{ messageId: 'mixedAliases' }],
    },
    {
      code: ["import { a } from 'jest/foo/bar';", "export * from 'ee_else_ce_jest/foo/bar';"].join(
        '\n',
      ),
      errors: [{ messageId: 'mixedAliases' }],
    },
  ],
});
