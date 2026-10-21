import { getNamedType, getNullableType, isListType, isObjectType } from 'graphql';

// Relay shape: the `*Connection` name suffix is a convention, `pageInfo` is the contract.
function isConnection(type) {
  const fields = type.getFields();
  return Boolean(fields.pageInfo && (fields.nodes || fields.edges));
}

function hasPaginationArgument(node) {
  return (node.arguments ?? []).some(({ name }) => name.value === 'first' || name.value === 'last');
}

// Fields the schema does not know (`@client`) have no `gqlType`; skip them rather than throw.
function isInsideList(context, node) {
  return context.sourceCode
    .getAncestors(node)
    .filter((ancestor) => ancestor.type === 'Field')
    .some((ancestor) => {
      const type = ancestor.typeInfo().gqlType;
      return Boolean(type) && isListType(getNullableType(type));
    });
}

export const graphqlNoUnboundedNestedConnection = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Disallow a connection field selected inside a list without a first: or last: argument',
      category: 'Best Practices',
    },
    messages: {
      unbounded:
        '`{{ name }}` is a connection selected inside a list without `first:` or `last:`; see doc/development/fe_guide/graphql.md#query-performance',
    },
    schema: [
      {
        type: 'object',
        properties: {
          allow: { type: 'array', items: { type: 'string' } },
        },
        additionalProperties: false,
      },
    ],
  },

  create(context) {
    // Without a schema the parser attaches no `typeInfo()`, so there is nothing to check.
    if (!context.sourceCode.parserServices?.schema) {
      return {};
    }

    const allow = context.options[0]?.allow ?? [];

    return {
      Field(node) {
        const type = node.typeInfo().gqlType;
        if (!type) return;

        const named = getNamedType(type);
        if (!isObjectType(named) || !isConnection(named)) return;

        const name = node.name.value;
        if (allow.includes(name)) return;
        if (hasPaginationArgument(node)) return;
        if (!isInsideList(context, node)) return;

        context.report({ node: node.name, messageId: 'unbounded', data: { name } });
      },
    };
  },
};
