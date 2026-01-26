export const vueRequireVueConstructorName = {
  meta: {
    type: 'problem',
    docs: {
      description: 'require a name property in Vue instance declarations',
      category: 'Best Practices',
      recommended: true,
    },
    fixable: 'code',
    schema: [],
    messages: {
      missingName: 'new Vue({}) calls must have a "name" property',
    },
  },

  create(context) {
    return {
      NewExpression(node) {
        // Check if this is a `new Vue()` call
        if (
          node.callee.type === 'Identifier' &&
          node.callee.name === 'Vue' &&
          node.arguments.length > 0
        ) {
          const arg = node.arguments[0];

          // Check if the argument is an object expression
          if (arg.type === 'ObjectExpression') {
            // Check if there's a 'name' property
            const hasNameProperty = arg.properties.some((prop) => {
              return (
                prop.type === 'Property' &&
                prop.key.type === 'Identifier' &&
                prop.key.name === 'name'
              );
            });

            if (!hasNameProperty) {
              context.report({
                node,
                messageId: 'missingName',
                fix(fixer) {
                  const sourceCode = context.getSourceCode();

                  // Try to find the component name from render function
                  let componentName = null;
                  const renderProperty = arg.properties.find((prop) => {
                    return (
                      prop.type === 'Property' &&
                      prop.key.type === 'Identifier' &&
                      prop.key.name === 'render'
                    );
                  });

                  if (renderProperty) {
                    const renderFunction = renderProperty.value;

                    // Handle both function expressions and arrow functions
                    if (
                      renderFunction.type === 'FunctionExpression' ||
                      renderFunction.type === 'ArrowFunctionExpression'
                    ) {
                      // Look for createElement calls in the function body
                      let createElementCall = null;

                      if (renderFunction.body.type === 'BlockStatement') {
                        // Function with block: render(h) { return h(Component); }
                        const returnStatement = renderFunction.body.body.find(
                          (stmt) => stmt.type === 'ReturnStatement',
                        );
                        if (returnStatement && returnStatement.argument) {
                          createElementCall = returnStatement.argument;
                        }
                      } else {
                        // Arrow function with implicit return: render: h => h(Component)
                        createElementCall = renderFunction.body;
                      }

                      // Extract component name from createElement call
                      if (
                        createElementCall &&
                        createElementCall.type === 'CallExpression' &&
                        createElementCall.arguments.length > 0
                      ) {
                        const firstArg = createElementCall.arguments[0];

                        // Handle identifier: createElement(MyComponent)
                        if (firstArg.type === 'Identifier') {
                          componentName = `${firstArg.name}Root`;
                        }
                        // Handle string literal: createElement('my-component')
                        else if (
                          firstArg.type === 'Literal' &&
                          typeof firstArg.value === 'string'
                        ) {
                          componentName = `${firstArg.value
                            .split(/[-_]/)
                            .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
                            .join('')}Root`;
                        }
                      }
                    }
                  }

                  // If we couldn't determine a name, don't provide a fix
                  if (!componentName) {
                    return null;
                  }
                  // Tf the name is too generic, don't provide a fix
                  if (['approot', 'componentroot'].includes(componentName.toLocaleLowerCase())) {
                    return null;
                  }

                  if (arg.properties.length === 0) {
                    const openBrace = sourceCode.getFirstToken(arg);
                    return fixer.insertTextAfter(openBrace, ` name: '${componentName}' `);
                  }

                  const firstProperty = arg.properties[0];
                  const before = sourceCode.getTokenBefore(firstProperty);
                  const indent = sourceCode
                    .getText()
                    .slice(
                      sourceCode.getIndexFromLoc(before.loc.end),
                      sourceCode.getIndexFromLoc(firstProperty.loc.start),
                    );

                  return fixer.insertTextBefore(
                    firstProperty,
                    `name: '${componentName}',${indent}`,
                  );
                },
              });
            }
          }
        }
      },
    };
  },
};
