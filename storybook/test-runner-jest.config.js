/* eslint-disable unicorn/filename-case */
const path = require('path');
const { getJestConfig } = require('@storybook/test-runner');

const baseConfig = getJestConfig();

/**
 * Jest config for the Storybook test-runner.
 *
 * Auto-discovered by `test-storybook` via a `test-runner-jest*` glob in the cwd
 * (the `storybook/` directory). We set these here rather than as `test-storybook`
 * CLI flags because `--outputFile` is a boolean flag for `test-storybook`: the
 * results filename is only forwarded to Jest as a trailing positional, so any
 * extra passthrough flag (e.g. `--maxWorkers`) wedges between Jest's
 * `--outputFile` and its value and breaks test discovery.
 *
 * `maxWorkers` caps parallelism to avoid RAM/CPU contention timeouts in CI.
 * `setupFilesAfterEnv` adds `test-runner-setup.js`, which enables Jest retries
 * for the "Execution context was destroyed" navigation flake.
 */
module.exports = {
  ...baseConfig,
  maxWorkers: 2,
  testTimeout: 60000,
  setupFilesAfterEnv: [
    ...(baseConfig.setupFilesAfterEnv || []),
    path.resolve(__dirname, 'test-runner-setup.js'),
  ],
};
