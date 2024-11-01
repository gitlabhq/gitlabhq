const path = require('path');
const { existsSync, readFileSync } = require('fs');
const { RuleTester } = require('eslint');
const { marked } = require('marked');
const rule = require('../../../../../tooling/eslint-config/eslint-local-rules/require_valid_help_page_path');

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
  languageOptions: { ecmaVersion: 2015 },
});

ruleTester.run('require-valid-help-page-path', rule, {
  valid: [
    `helpPagePath();`,
    `helpPagePath('${VALID_PATH}');`,
    `helpPagePath('${VALID_PATH_MD}');`,
    `helpPagePath('${VALID_PATH_HTML}');`,
    `helpPagePath('${VALID_PATH}#${VALID_ANCHOR}');`,
    `helpPagePath('${VALID_PATH_MD}#${VALID_ANCHOR}');`,
    `helpPagePath('${VALID_PATH_HTML}#${VALID_ANCHOR}');`,
    `helpPagePath('${VALID_PATH}', { anchor: '${VALID_ANCHOR}' });`,
    `helpPagePath('${VALID_PATH}', { anchor: '#${VALID_ANCHOR}' });`,
    `helpPagePath('${VALID_PATH_MD}', { anchor: '${VALID_ANCHOR}' });`,
    `helpPagePath('${VALID_PATH_HTML}', { anchor: '${VALID_ANCHOR}' });`,
  ],
  invalid: [
    {
      code: 'helpPagePath(variable);',
      errors: [{ message: "`helpPagePath`'s first argument must be a string literal" }],
    },
    {
      code: `helpPagePath('${INVALID_PATH}');`,
      errors: [
        {
          message: `\`${path.join(__dirname, '../../../../../doc', INVALID_PATH, 'index.md')}\` does not exist.`,
        },
      ],
    },
    {
      code: `helpPagePath('${VALID_PATH}#${INVALID_ANCHOR}');`,
      errors: [
        {
          message: `\`#${INVALID_ANCHOR}\` not found in \`${path.join(__dirname, '../../../../../doc', VALID_PATH)}.md\``,
        },
      ],
    },
    {
      code: `helpPagePath('${VALID_PATH}', { anchor: '${INVALID_ANCHOR}' });`,
      errors: [
        {
          message: `\`#${INVALID_ANCHOR}\` not found in \`${path.join(__dirname, '../../../../../doc', VALID_PATH)}.md\``,
        },
      ],
    },
  ],
});
