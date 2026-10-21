import { RuleTester } from 'eslint';
import { parser as graphqlParser } from '@graphql-eslint/eslint-plugin/parser';
import { graphqlNoUnboundedNestedConnection } from '../../../../../tooling/eslint-config/eslint-local-rules/graphql_no_unbounded_nested_connection';

const schemaSdl = `
  type PageInfo { hasNextPage: Boolean! }
  type Report { id: ID! }
  type ReportConnection { pageInfo: PageInfo! nodes: [Report] }

  type Thing {
    id: ID!
    reports(first: Int, last: Int): ReportConnection
    assignees(first: Int): ReportConnection
    plainList: [Thing!]
    related: ThingList
  }
  type ThingEdge { node: Thing }
  type ThingList { pageInfo: PageInfo! nodes: [Thing] edges: [ThingEdge] }

  type Message { id: ID! }
  type MessageConnection { pageInfo: PageInfo! nodes: [Message] }
  type Snapshot { messages(first: Int): MessageConnection }
  type Session { latestSnapshot: Snapshot }
  type SessionConnection { pageInfo: PageInfo! nodes: [Session] }

  type Query {
    things(first: Int): ThingList
    reports(first: Int): ReportConnection
    sessions(first: Int): SessionConnection
    plainList: [Thing!]
  }
`;

const ruleTester = new RuleTester({
  languageOptions: {
    parser: graphqlParser,
    parserOptions: { schemaSdl },
  },
});

const unbounded = (name) => ({ messageId: 'unbounded', data: { name } });

ruleTester.run('graphql-no-unbounded-nested-connection', graphqlNoUnboundedNestedConnection, {
  valid: [
    {
      name: 'allows a field named in the allow option',
      code: 'query { things(first: 20) { nodes { assignees { nodes { id } } } } }',
      options: [{ allow: ['assignees'] }],
    },
    {
      name: 'allow matches the field name, not the alias',
      code: 'query { things(first: 20) { nodes { assignees: reports { nodes { id } } } } }',
      options: [{ allow: ['reports'] }],
    },
    {
      name: 'accepts first: 1',
      code: 'query { things(first: 20) { nodes { reports(first: 1) { nodes { id } } } } }',
    },
    {
      name: 'accepts last: 5',
      code: 'query { things(first: 20) { nodes { reports(last: 5) { nodes { id } } } } }',
    },
    {
      name: 'accepts a variable as first:',
      code: 'query ($n: Int) { things(first: 20) { nodes { reports(first: $n) { nodes { id } } } } }',
    },
    {
      name: 'allows a top-level connection',
      code: 'query { reports { nodes { id } } }',
    },
    {
      name: 'allows a connection in a bare fragment',
      code: 'fragment F on Thing { reports { nodes { id } } }',
    },
    {
      name: 'ignores a plain list inside a list',
      code: 'query { things(first: 20) { nodes { plainList { id } } } }',
    },
    {
      name: 'ignores a local field the schema does not know',
      code: 'query { things(first: 20) { nodes { stuff @client { nodes { id } } } } }',
    },
    {
      name: 'allows a bounded connection in the documented example',
      code: `query {
        sessions(first: 20) { nodes { latestSnapshot { messages(first: 5) { nodes { id } } } } }
      }`,
    },
  ],
  invalid: [
    {
      name: 'reports a connection under a list without first:/last:',
      code: 'query { things(first: 20) { nodes { reports { nodes { id } } } } }',
      errors: [unbounded('reports')],
    },
    {
      name: 'reports an aliased connection by its field name',
      code: 'query { things(first: 20) { nodes { mine: reports { nodes { id } } } } }',
      errors: [unbounded('reports')],
    },
    {
      name: 'does not let the alias satisfy the allow option',
      code: 'query { things(first: 20) { nodes { assignees: reports { nodes { id } } } } }',
      options: [{ allow: ['assignees'] }],
      errors: [unbounded('reports')],
    },
    {
      name: 'reports only the fields outside the allow option',
      code: `query {
        things(first: 20) { nodes { assignees { nodes { id } } reports { nodes { id } } } }
      }`,
      options: [{ allow: ['assignees'] }],
      errors: [unbounded('reports')],
    },
    {
      name: 'reports a connection inside an inline fragment under a list',
      code: 'query { things(first: 5) { nodes { ... on Thing { reports { nodes { id } } } } } }',
      errors: [unbounded('reports')],
    },
    {
      name: 'reports a connection reached through edges { node }',
      code: 'query { things(first: 20) { edges { node { reports { nodes { id } } } } } }',
      errors: [unbounded('reports')],
    },
    {
      name: 'reports a connection under a plain list',
      code: 'query { plainList { reports { nodes { id } } } }',
      errors: [unbounded('reports')],
    },
    {
      name: 'reports a connection nested under several lists',
      code: 'query { sessions(first: 20) { nodes { latestSnapshot { messages { nodes { id } } } } } }',
      errors: [unbounded('messages')],
    },
    {
      name: 'detects a connection whose type name has no Connection suffix',
      code: 'query { things(first: 20) { nodes { related { nodes { id } } } } }',
      errors: [unbounded('related')],
    },
  ],
});

const schemalessRuleTester = new RuleTester({
  languageOptions: {
    parser: graphqlParser,
    parserOptions: { graphQLConfig: { schema: null, documents: [] } },
  },
});

schemalessRuleTester.run(
  'graphql-no-unbounded-nested-connection without a schema',
  graphqlNoUnboundedNestedConnection,
  {
    valid: [
      {
        name: 'reports nothing when no schema is loaded',
        code: 'query { things(first: 20) { nodes { reports { nodes { id } } } } }',
      },
    ],
    invalid: [],
  },
);
