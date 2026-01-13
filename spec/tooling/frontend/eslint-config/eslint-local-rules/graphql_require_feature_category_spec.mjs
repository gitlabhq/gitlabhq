import { vi } from 'vitest';
import { RuleTester } from 'eslint';
// eslint-disable-next-line import/no-unresolved
import { parser as graphqlParser } from '@graphql-eslint/eslint-plugin/parser';
import { graphqlRequireFeatureCategory } from '../../../../../tooling/eslint-config/eslint-local-rules/graphql_require_feature_category';

// Mock the yaml module to return a predefined list of categories for testing
vi.mock('yaml', () => ({
  default: {
    parse: vi.fn(() => [
      'project_management',
      'code_review_workflow',
      'continuous_integration',
      'team_planning',
    ]),
  },
}));

// Mock fs to simulate file reading
vi.mock('node:fs', () => ({
  readFileSync: vi.fn(() => ''),
}));

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

ruleTester.run('graphql-require-feature-category', graphqlRequireFeatureCategory, {
  valid: [
    // Valid mutation with correct comment format
    {
      code: `# @feature_category: project_management
mutation testMutation {
  field
}`,
    },
    // Valid query with correct comment format
    {
      code: `# @feature_category: code_review_workflow
query testQuery {
  field
}`,
    },
    // Valid with other comments before
    {
      code: `# This is a mutation
# @feature_category: continuous_integration
mutation testMutation {
  field
}`,
    },
    // Fragment files should not be checked (no query/mutation)
    {
      code: `fragment TestFragment on Type {
  field
}`,
    },
    // Multiple operations with feature category
    {
      code: `# @feature_category: team_planning
query testQuery1 {
  field
}

query testQuery2 {
  field
}`,
    },
    // Mutation and query in same file
    {
      code: `# @feature_category: project_management
mutation testMutation {
  field
}

query testQuery {
  field
}`,
    },
    // Valid subscription with correct comment format
    {
      code: `# @feature_category: continuous_integration
subscription testSubscription {
  field
}`,
    },
    // Subscription with other comments before
    {
      code: `# This is a subscription
# @feature_category: code_review_workflow
subscription testSubscription {
  field
}`,
    },
    // Multiple subscriptions with feature category
    {
      code: `# @feature_category: team_planning
subscription testSubscription1 {
  field
}

subscription testSubscription2 {
  field
}`,
    },
  ],
  invalid: [
    // Missing feature category comment
    {
      code: `mutation testMutation {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Missing feature category for query
    {
      code: `query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Invalid category value
    {
      code: `# @feature_category: invalid_category
mutation testMutation {
  field
}`,
      errors: [
        {
          messageId: 'invalidCategory',
          data: { category: 'invalid_category' },
        },
      ],
    },
    // Invalid category with query
    {
      code: `# @feature_category: wrong_value
query testQuery {
  field
}`,
      errors: [
        {
          messageId: 'invalidCategory',
          data: { category: 'wrong_value' },
        },
      ],
    },
    // Comment exists but wrong format (missing space after #)
    {
      code: `#@feature_category: project_management
mutation testMutation {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Comment exists but wrong format (missing space after colon)
    {
      code: `# @feature_category:project_management
mutation testMutation {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Multiple operations without feature category
    {
      code: `query testQuery1 {
  field
}

query testQuery2 {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Missing feature category for subscription
    {
      code: `subscription testSubscription {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Invalid category with subscription
    {
      code: `# @feature_category: invalid_subscription_category
subscription testSubscription {
  field
}`,
      errors: [
        {
          messageId: 'invalidCategory',
          data: { category: 'invalid_subscription_category' },
        },
      ],
    },
    // Subscription with wrong format (missing space after #)
    {
      code: `#@feature_category: project_management
subscription testSubscription {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
    // Multiple subscriptions without feature category
    {
      code: `subscription testSubscription1 {
  field
}

subscription testSubscription2 {
  field
}`,
      errors: [
        {
          messageId: 'missingCategory',
        },
      ],
    },
  ],
});
