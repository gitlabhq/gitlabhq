import { RuleTester } from 'eslint';
import { pageEntrypointMustExecute } from '../../../../../tooling/eslint-config/eslint-local-rules/page_entrypoint_must_execute.mjs';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
});

const NO_EXPORT = { messageId: 'noExport' };
const MISSING_SIDE_EFFECT = { messageId: 'missingSideEffect' };

ruleTester.run('page-entrypoint-must-execute', pageEntrypointMustExecute, {
  valid: [
    // --- Has a top-level side effect, no exports ---

    // Plain top-level invocation.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
      `,
    },
    // Bare side-effect import: the canonical delegation pattern.
    // Used by CE pages that defer to a non-pages module, and by EE
    // pages that re-import their CE counterpart.
    {
      code: `import '~/snippet/snippet_show';`,
    },
    {
      code: `import '~/pages/projects/show/index';`,
    },
    // Bare side-effect imports mixed with named imports are still valid
    // as long as the bare import is present.
    {
      code: `
        import { unused } from '~/unrelated';
        import '~/pages/projects/show/index';
      `,
    },
    // `new SomeClass()` is a side-effect statement.
    {
      code: `
        import Thing from '~/thing';
        new Thing(); // eslint-disable-line no-new
      `,
    },
    // Top-level conditional dispatch (matches the pattern used by
    // pages/projects/issues/show/index.js).
    {
      code: `
        import { check } from '~/thing';
        if (check()) {
          doWork();
        }
      `,
    },
    // Top-level `await` is a side-effect statement.
    {
      code: `
        const mod = await import('~/thing');
        mod.init();
      `,
    },
    // Multiple side-effect statements, mixed with declarations.
    {
      code: `
        import { initA, initB } from '~/things';
        const ready = true;
        initA();
        initB();
      `,
    },
    // Helper functions declared alongside an actual invocation are fine.
    {
      code: `
        function helper() { return 1; }
        helper();
      `,
    },
  ],

  invalid: [
    // --- noExport ---

    // Named export with declaration.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        export const helper = () => {};
      `,
      errors: [NO_EXPORT],
    },
    // Named export of an existing binding.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        const initPage = () => {};
        export { initPage };
      `,
      errors: [NO_EXPORT],
    },
    // Default export of an expression.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        export default function initPage() {}
      `,
      errors: [NO_EXPORT],
    },
    // Default export of an identifier.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        const initPage = () => {};
        export default initPage;
      `,
      errors: [NO_EXPORT],
    },
    // Re-export from another module.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        export * from '~/thing';
      `,
      errors: [NO_EXPORT],
    },
    // Re-export of a named binding.
    {
      code: `
        import { initThing } from '~/thing';
        initThing();
        export { initThing as somethingElse } from '~/thing';
      `,
      errors: [NO_EXPORT],
    },

    // --- missingSideEffect ---

    // Imports only.
    {
      code: `
        import { initThing } from '~/thing';
        import { initOther } from '~/other';
      `,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Imports plus a function declaration that is never called.
    {
      code: `
        import { initThing } from '~/thing';
        function initPage() {
          initThing();
        }
      `,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Imports plus a class declaration that is never instantiated.
    {
      code: `
        import { Thing } from '~/thing';
        class Page {
          constructor() {
            new Thing();
          }
        }
      `,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Variable declarations only (initializer side effects don't count).
    {
      code: `
        import { compute } from '~/thing';
        const value = compute();
      `,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Completely empty file.
    {
      code: ``,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Only empty statements.
    {
      code: `;;;`,
      errors: [MISSING_SIDE_EFFECT],
    },
    // Named imports only, no invocation.
    {
      code: `
        import { initA } from '~/a';
        import { initB } from '~/b';
      `,
      errors: [MISSING_SIDE_EFFECT],
    },

    // Defines and exports an init helper without invoking it. This is the
    // exact real-world pattern the original `no-exports-in-page-entrypoints`
    // rule was designed to catch. Only `noExport` fires (the export itself
    // counts as a top-level side-effect statement, so the side-effect check
    // is satisfied); fixing the export is the actionable next step anyway.
    {
      code: `
        import { initThing } from '~/thing';
        export const initPage = () => {
          initThing();
        };
      `,
      errors: [NO_EXPORT],
    },
  ],
});
