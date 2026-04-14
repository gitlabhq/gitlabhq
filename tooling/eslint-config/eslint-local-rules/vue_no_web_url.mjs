import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';
import { memberExpressionValidator } from './utils/no_web_url_utils.mjs';

export const vueNoWebUrl = {
  meta: {
    type: 'error',
    docs: {
      description:
        'Prevent usage of webUrl or web_url properties in Vue templates. Use webPath or web_path instead.',
    },
    schema: [],
  },
  create(context) {
    return defineTemplateBodyVisitor(context, {
      MemberExpression(node) {
        memberExpressionValidator(context, node);
      },
    });
  },
};
