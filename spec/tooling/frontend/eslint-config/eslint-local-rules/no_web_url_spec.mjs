import { RuleTester } from 'eslint';
import { noWebUrl } from '../../../../../tooling/eslint-config/eslint-local-rules/no_web_url';
import { ERROR_MESSAGE } from '../../../../../tooling/eslint-config/eslint-local-rules/utils/no_web_url_utils';

const ruleTester = new RuleTester({
  languageOptions: { ecmaVersion: 2015 },
});

ruleTester.run('no-web-url', noWebUrl, {
  valid: [
    {
      code: 'object.webPath',
    },
    {
      code: 'object.web_path',
    },
    {
      code: "object['webPath']",
    },
    {
      code: "object['web_path']",
    },
    {
      code: 'object.otherProperty',
    },
    {
      code: 'object.url',
    },
    {
      code: 'nested.object.webPath',
    },
  ],

  invalid: [
    {
      code: 'object.webUrl',
      errors: [ERROR_MESSAGE],
    },
    {
      code: 'object.web_url',
      errors: [ERROR_MESSAGE],
    },
    {
      code: "object['webUrl']",
      errors: [ERROR_MESSAGE],
    },
    {
      code: "object['web_url']",
      errors: [ERROR_MESSAGE],
    },
    {
      code: 'nested.object.webUrl',
      errors: [ERROR_MESSAGE],
    },
    {
      code: 'this.item.webUrl',
      errors: [ERROR_MESSAGE],
    },
    {
      code: 'data.project.web_url',
      errors: [ERROR_MESSAGE],
    },
    {
      code: "item['webUrl'].toString()",
      errors: [ERROR_MESSAGE],
    },
  ],
});
