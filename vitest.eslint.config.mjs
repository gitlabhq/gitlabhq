/* eslint-disable import/no-default-export, import/no-unresolved */
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['./spec/tooling/frontend/eslint-config/eslint-local-rules/*_spec.mjs'],
    setupFiles: ['spec/tooling/frontend/eslint-config/eslint-local-rules/setup.mjs'],
  },
});
