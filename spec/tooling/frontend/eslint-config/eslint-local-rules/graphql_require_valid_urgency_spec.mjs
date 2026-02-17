import { RuleTester } from 'eslint';
// eslint-disable-next-line import/no-unresolved
import { parser as graphqlParser } from '@graphql-eslint/eslint-plugin/parser';
import { graphqlRequireValidUrgency } from '../../../../../tooling/eslint-config/eslint-local-rules/graphql_require_valid_urgency';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: graphqlParser,
    parserOptions: {
      graphQLConfig: {
        schema: null,
        documents: [],
      },
    },
  },
});

ruleTester.run('graphql-require-valid-urgency', graphqlRequireValidUrgency, {
  valid: [
    // Query without urgency comment (optional, so this is valid)
    {
      code: `# @feature_category: project_management
query testQuery {
  field
}`,
    },
    // Mutation without urgency comment
    {
      code: `# @feature_category: code_review_workflow
mutation testMutation {
  field
}`,
    },
    // Subscription without urgency comment
    {
      code: `# @feature_category: continuous_integration
subscription testSubscription {
  field
}`,
    },
    // Fragment files should not be checked
    {
      code: `fragment TestFragment on Type {
  field
}`,
    },
    // Query with valid urgency: high
    {
      code: `# @feature_category: project_management
# @urgency: high
query testQuery {
  field
}`,
    },
    // Query with valid urgency: medium
    {
      code: `# @feature_category: project_management
# @urgency: medium
query testQuery {
  field
}`,
    },
    // Query with valid urgency: default
    {
      code: `# @feature_category: project_management
# @urgency: default
query testQuery {
  field
}`,
    },
    // Query with valid urgency: low
    {
      code: `# @feature_category: project_management
# @urgency: low
query testQuery {
  field
}`,
    },
    // Mutation with valid urgency
    {
      code: `# @feature_category: code_review_workflow
# @urgency: high
mutation testMutation {
  field
}`,
    },
    // Subscription with valid urgency
    {
      code: `# @feature_category: continuous_integration
# @urgency: medium
subscription testSubscription {
  field
}`,
    },
    // Multiple comments with valid urgency
    {
      code: `# This is a comment
# @feature_category: team_planning
# @urgency: low
query testQuery {
  field
}`,
    },
  ],
  invalid: [
    // Query with invalid urgency value
    {
      code: `# @feature_category: project_management
# @urgency: critical
query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'critical' },
        },
      ],
    },
    // Mutation with invalid urgency value
    {
      code: `# @feature_category: code_review_workflow
# @urgency: urgent
mutation testMutation {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'urgent' },
        },
      ],
    },
    // Subscription with invalid urgency value
    {
      code: `# @feature_category: continuous_integration
# @urgency: immediate
subscription testSubscription {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'immediate' },
        },
      ],
    },
    // Wrong capitalization
    {
      code: `# @feature_category: project_management
# @urgency: High
query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'High' },
        },
      ],
    },
    // Invalid format (provided invalid urgency value) - won't match the pattern, so no urgency found
    {
      code: `# @feature_category: project_management
# @urgency: very-high
query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'very-high' },
        },
      ],
    },
    // No whitespace between colon and urgency value
    {
      code: `# @feature_category: project_management
# @urgency:high
query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'invalidUrgency',
          data: { urgency: 'high' },
        },
      ],
    },
  ],
});
