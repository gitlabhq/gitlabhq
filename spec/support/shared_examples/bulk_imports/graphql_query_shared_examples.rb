# frozen_string_literal: true

RSpec.shared_examples 'a valid Direct Transfer GraphQL query' do
  let(:graphql_log) do
    GitlabSchema.execute(
      query.to_s,
      variables: query.variables
    )

    RequestStore.store[:graphql_logs].first
  end

  it 'has a valid query' do
    parsed_query = GraphQL::Query.new(
      GitlabSchema,
      query.to_s,
      variables: query.variables
    )

    result = GitlabSchema.static_validator.validate(parsed_query)

    expect(result[:errors]).to be_empty
  end

  it 'does not use any deprecated GraphQL schema' do
    expect(graphql_log.keys).to include(
      :used_deprecated_fields,
      :used_deprecated_arguments
    )

    # Avoid false-positive of an experiment argument with a default
    message = '`includeSiblingProjects` argument is no longer an experiment. Please remove code from here until
      `#end-remove`'
    expect(Resolvers::NamespaceProjectsResolver.arguments['includeSiblingProjects']&.deprecation).to be_experiment,
      message
    graphql_log[:used_deprecated_arguments].delete('NamespaceProjectsResolver.includeSiblingProjects')
    # end-remove

    expect(graphql_log[:used_deprecated_fields]).to be_empty
    expect(graphql_log[:used_deprecated_arguments]).to be_empty
  end

  it 'does not exceed max authenticated complexity' do
    expect(graphql_log).to have_key(:complexity)
    expect(graphql_log[:complexity]).to be < GitlabSchema::AUTHENTICATED_MAX_COMPLEXITY
  end

  it 'does not exceed max depth' do
    expect(graphql_log).to have_key(:depth)
    expect(graphql_log[:depth]).to be < GitlabSchema::DEFAULT_MAX_DEPTH
  end
end
