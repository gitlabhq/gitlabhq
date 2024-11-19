const path = require('path');
const { existsSync, readFileSync } = require('fs');
const { RuleTester } = require('eslint');
const { marked } = require('marked');
const vueEslintParser = require('vue-eslint-parser');
const rule = require('../../../../../tooling/eslint-config/eslint-local-rules/vue_require_valid_help_page_link_component');

jest.mock('fs');
jest.mock('marked');

const VALID_PATH = 'this/file/exists';
const VALID_PATH_MD = 'this/file/exists.md';
const VALID_PATH_HTML = 'this/file/exists.html';
const INVALID_PATH = 'this/file/does/not/exist';
const VALID_ANCHOR = 'valid-anchor';
const INVALID_ANCHOR = 'invalid-anchor';

existsSync.mockImplementation((docsPath) => {
  if (docsPath.includes(VALID_PATH)) {
    return true;
  }
  return false;
});

readFileSync.mockImplementation(() => '');

marked.parse.mockImplementation(() => VALID_ANCHOR);

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

function wrapTemplate(content) {
  return `<template>${content}</template>`;
}

function makeComponent(href, anchor = null) {
  const anchorProp = anchor ? ` anchor="${anchor}"` : '';
  return wrapTemplate(`
    <help-page-link href="${href}"${anchorProp}>
      Link to doc
    </help-page-link>
  `);
}

ruleTester.run('require-valid-help-page-path', rule, {
  valid: [
    makeComponent(VALID_PATH),
    makeComponent(VALID_PATH_MD),
    makeComponent(VALID_PATH_HTML),
    makeComponent(`${VALID_PATH}#${VALID_ANCHOR}`),
    makeComponent(`${VALID_PATH_MD}#${VALID_ANCHOR}`),
    makeComponent(`${VALID_PATH_HTML}#${VALID_ANCHOR}`),
    makeComponent(VALID_PATH, VALID_ANCHOR),
    makeComponent(VALID_PATH_MD, VALID_ANCHOR),
    makeComponent(VALID_PATH_HTML, VALID_ANCHOR),
  ],
  invalid: [
    {
      code: wrapTemplate('<help-page-link :href="$options.href">Link</help-page-link>'),
      errors: [
        {
          message: 'The `href` prop must be passed as a string literal.',
        },
      ],
    },
    {
      code: makeComponent(INVALID_PATH),
      errors: [
        {
          message: `\`${path.join(__dirname, '../../../../../doc', INVALID_PATH, 'index.md')}\` does not exist.`,
        },
      ],
    },
    {
      code: makeComponent(`${VALID_PATH}#${INVALID_ANCHOR}`),
      errors: [
        {
          message: `\`#${INVALID_ANCHOR}\` not found in \`${path.join(__dirname, '../../../../../doc', VALID_PATH)}.md\``,
        },
      ],
    },
    {
      code: makeComponent(VALID_PATH, INVALID_ANCHOR),
      errors: [
        {
          message: `\`#${INVALID_ANCHOR}\` not found in \`${path.join(__dirname, '../../../../../doc', VALID_PATH)}.md\``,
        },
      ],
    },
  ],
});
