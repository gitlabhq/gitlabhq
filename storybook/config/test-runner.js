const { injectAxe, checkA11y, configureAxe } = require('axe-playwright');
const { getStoryContext } = require('@storybook/test-runner');

/**
 * See https://storybook.js.org/docs/7/writing-tests/test-runner#test-hook-api
 * to learn more about the test-runner hooks API.
 */
module.exports = {
  async preVisit(page) {
    await injectAxe(page);
  },
  async postVisit(page, context) {
    const storyContext = await getStoryContext(page, context);

    if (!storyContext.parameters?.a11y?.disable) {
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
