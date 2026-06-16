/* eslint-disable unicorn/filename-case */

/**
 * Per-test setup for the Storybook test-runner (runs in the Jest test
 * environment via `setupFilesAfterEnv`).
 *
 * The test-runner already retries a smoke-test once when the story render
 * throws "Execution context was destroyed, most likely because of a
 * navigation" (a race where the rendering `page.evaluate` is torn down by an
 * in-flight navigation). That inline retry is single and unguarded, so when the
 * race recurs the test still fails and the job goes red flakily.
 *
 * jest-circus `retryTimes` re-runs the whole test on failure, and each run
 * carries the test-runner's own inline retry, so the navigation race has to
 * lose repeatedly before a test is reported as failed. A genuinely broken story
 * fails every attempt, so this masks flakiness without hiding real breakage.
 */
jest.retryTimes(2, { logErrorsBeforeRetry: true });
