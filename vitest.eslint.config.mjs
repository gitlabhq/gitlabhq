import { createRequire } from 'node:module';
import { defineConfig } from 'vitest/config';

const require = createRequire(import.meta.url);

export default defineConfig({
  resolve: {
    // The externalized @graphql-eslint parser loads the CJS build of graphql; point the rules at the
    // same file so the two sides share one module instance and graphql's `instanceof` checks hold.
    alias: { graphql: require.resolve('graphql') },
  },
  test: {
    include: ['./spec/tooling/frontend/eslint-config/eslint-local-rules/*_spec.mjs'],
    setupFiles: ['spec/tooling/frontend/eslint-config/eslint-local-rules/setup.mjs'],
  },
});
