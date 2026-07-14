# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/mcp/use_graphql_query_file'

RSpec.describe RuboCop::Cop::Mcp::UseGraphqlQueryFile, feature_category: :mcp_server do
  it 'flags an inline HEREDOC operation' do
    expect_offense(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        operation_name: 'createNote',
        graphql_operation: <<~GRAPHQL
                           ^^^^^^^^^^ Load MCP tool GraphQL operations from a .graphql file under app/graphql/queries/mcp/ via load_graphql(...) instead of an inline string, so they are validated against GitlabSchema at build time. See https://gitlab.com/gitlab-org/gitlab/-/issues/603389.
          mutation CreateNote { createNote { errors } }
        GRAPHQL
      }
    RUBY
  end

  it 'flags an inline single-line string operation' do
    expect_offense(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        graphql_operation: 'query { foo }'
                           ^^^^^^^^^^^^^^^ Load MCP tool GraphQL operations from a .graphql file under app/graphql/queries/mcp/ via load_graphql(...) instead of an inline string, so they are validated against GitlabSchema at build time. See https://gitlab.com/gitlab-org/gitlab/-/issues/603389.
      }
    RUBY
  end

  it 'flags an interpolated inline operation' do
    expect_offense(<<~'RUBY')
      register_version VERSIONS[:v0_1_0], {
        graphql_operation: "query { #{field} }"
                           ^^^^^^^^^^^^^^^^^^^^ Load MCP tool GraphQL operations from a .graphql file under app/graphql/queries/mcp/ via load_graphql(...) instead of an inline string, so they are validated against GitlabSchema at build time. See https://gitlab.com/gitlab-org/gitlab/-/issues/603389.
      }
    RUBY
  end

  it 'does not flag load_graphql(...)' do
    expect_no_offenses(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        operation_name: 'createNote',
        graphql_operation: load_graphql('work_items/create_note.mutation.graphql')
      }
    RUBY
  end

  it 'does not flag a lambda that composes the operation at load time' do
    expect_no_offenses(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        operation_name: 'namespace',
        graphql_operation: -> { build_query }
      }
    RUBY
  end

  it 'does not flag other string pairs' do
    expect_no_offenses(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        operation_name: 'createNote'
      }
    RUBY
  end

  it 'does not auto-correct' do
    expect_offense(<<~RUBY)
      register_version VERSIONS[:v0_1_0], {
        graphql_operation: 'query { foo }'
                           ^^^^^^^^^^^^^^^ Load MCP tool GraphQL operations from a .graphql file under app/graphql/queries/mcp/ via load_graphql(...) instead of an inline string, so they are validated against GitlabSchema at build time. See https://gitlab.com/gitlab-org/gitlab/-/issues/603389.
      }
    RUBY

    expect_no_corrections
  end
end
