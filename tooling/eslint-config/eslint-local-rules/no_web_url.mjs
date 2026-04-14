import { memberExpressionValidator } from './utils/no_web_url_utils.mjs';

export const noWebUrl = {
  meta: {
    type: 'error',
    docs: {
      description:
        'Prevent usage of webUrl or web_url properties. Use webPath or web_path instead.',
    },
    schema: [],
  },
  create(context) {
    return {
      MemberExpression(node) {
        memberExpressionValidator(context, node);
      },
    };
  },
};
