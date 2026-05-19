# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization.workItemTypes', :with_current_organization, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user, organizations: [current_organization]) }
  let_it_be(:all_system_defined_types) { ::WorkItems::TypesFramework::Provider.new(current_organization).available_types }
  let_it_be(:all_system_defined_type_names) { all_system_defined_types.map(&:name) }

  let(:query_param) { { 'id' => current_organization.to_gid } }
  let(:query) do
    graphql_query_for('organization', query_param,
      'workItemTypes { nodes { id name widgetDefinitions { type } } }')
  end

  it 'returns work item types for the organization' do
    post_graphql(query, current_user: current_user)
    expect(graphql_data_at('organization', 'workItemTypes', 'nodes')).not_to be_empty
  end

  it 'returns system-defined work item types' do
    post_graphql(query, current_user: current_user)

    returned_types = graphql_data_at('organization', 'workItemTypes', 'nodes')
    type_names = returned_types.pluck('name')

    expect(type_names).to all(be_in(all_system_defined_type_names))

    expect(returned_types.size).to eq(all_system_defined_types.count)
  end

  context 'when organization id is not set' do
    let(:query_param) { {} }

    it 'returns work item types for the organization' do
      post_graphql(query, current_user: current_user)
      expect(graphql_data_at('organization', 'workItemTypes', 'nodes')).not_to be_empty
    end
  end
end
