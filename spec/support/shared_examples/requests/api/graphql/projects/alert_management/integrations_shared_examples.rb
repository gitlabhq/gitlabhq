# frozen_string_literal: true

RSpec.shared_examples 'GraphQL query with several integrations requested' do |graphql_query_name:|
  context 'when several HTTP integrations requested' do
    let(:params_ai) { { id: global_id_of(active_http_integration) } }
    let(:params_ii) { { id: global_id_of(inactive_http_integration) } }
    let(:fields) { "nodes { id name }" }

    let(:single_selection_query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        <<~QUERY
        ai: #{query_graphql_field(graphql_query_name, params_ai, fields)}
        QUERY
      )
    end

    let(:multi_selection_query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        <<~QUERY
        ai: #{query_graphql_field(graphql_query_name, params_ai, fields)}
        ii: #{query_graphql_field(graphql_query_name, params_ii, fields)}
        QUERY
      )
    end

    it 'returns the correct properties of the integrations', :aggregate_failures do
      post_graphql(multi_selection_query, current_user: current_user)

      expect(graphql_data.dig('project', 'ai', 'nodes')).to match a_graphql_entity_for(
        active_http_integration, :name
      )

      expect(graphql_data.dig('project', 'ii', 'nodes')).to match a_graphql_entity_for(
        inactive_http_integration, :name
      )
    end

    it 'batches queries' do
      expect { post_graphql(multi_selection_query, current_user: current_user) }
        .to issue_same_number_of_queries_as { post_graphql(single_selection_query, current_user: current_user) }.ignoring_cached_queries
    end
  end
end
