const DISALLOWED_VALUES = ['webUrl', 'web_url'];

export const ERROR_MESSAGE =
  'Avoid using webUrl or web_url. Use webPath or web_path instead. See https://docs.gitlab.com/development/urls_in_gitlab/#graphql-queries';

export const memberExpressionValidator = (context, node) => {
  const { property } = node;
  const value = property.name ?? property.value;

  if (DISALLOWED_VALUES.includes(value)) {
    context.report({
      node,
      message: ERROR_MESSAGE,
    });
  }
};
