/* eslint-disable import/no-unresolved, import/no-default-export */
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['./spec/frontend/scripts/infection_scanner/*_spec.mjs'],
  },
});
