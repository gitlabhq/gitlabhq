/* eslint-disable unicorn/filename-case */
const { injectAxe, checkA11y, configureAxe } = require('axe-playwright');
const { getStoryContext } = require('@storybook/test-runner');

/**
 * See https://storybook.js.org/docs/7/writing-tests/test-runner#test-hook-api
 * to learn more about the test-runner hooks API.
 */
module.exports = {
  async postVisit(page, context) {
    const storyContext = await getStoryContext(page, context);

    if (!storyContext.parameters?.a11y?.disable) {
      // Inject axe here (postVisit), after the story has rendered, rather than
      // in preVisit. The test-runner renders stories in-place via
      // `setCurrentStory`, and the first story's render fires a `framenavigated`
      // event (the no-id -> `?id=...` URL transition). If axe is already
      // injected at that point, that navigation tears down the execution
      // context the in-flight render evaluation depends on, surfacing as
      // "Execution context was destroyed" on the first story in each file.
      await injectAxe(page);

      // Merge story-specific rules with global rules
      const storyRules = storyContext.parameters?.a11y?.config?.rules || [];
      const globalRules = [
        {
          id: 'link-in-text-block',
          enabled: false,
        },
      ];
      const mergedRules = [...globalRules, ...storyRules];

      await configureAxe(page, {
        rules: mergedRules,
      });

      await checkA11y(
        page,
        '#storybook-root',
        {
          detailedReport: true,
          detailedReportOptions: {
            html: true,
          },
        },
        false,
        'v2',
      );
    }
  },
};
