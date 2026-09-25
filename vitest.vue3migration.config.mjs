/* eslint-disable import-x/no-default-export */
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: [
      './spec/frontend/config/vue3migration/**/*_spec.mjs',
      './spec/frontend/scripts/infection_scanner/*_spec.mjs',
    ],
  },
});
