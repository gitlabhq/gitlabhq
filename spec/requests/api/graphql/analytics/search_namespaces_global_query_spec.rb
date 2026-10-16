# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searchAnalyticsDashboardNamespacesGlobal query',
  feature_category: :custom_dashboards_foundation do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  # The closer match sorts last by name and first by id, so each ordering example
  # fails under both the `name_asc` default and the `id_desc` fallback.
  let_it_be(:closest_group) { create(:group, :private, name: 'Zeta', developers: user) }
  let_it_be(:distant_group) { create(:group, :private, name: 'Analytics zeta reporting', developers: user) }
  let_it_be(:non_member_group) { create(:group, :public, name: 'Zeta unaffiliated') }

  # Kept out of the groups above: `searchNamespaces: true` would match these
  # through their namespace rather than on their own name.
  let_it_be(:project_parent) { create(:group, :private, name: 'Holding', developers: user) }
  let_it_be(:closest_project) do
    create(:project, :private, name: 'Zeta', group: project_parent, developers: user)
  end

  let_it_be(:distant_project) do
    create(:project, :private, name: 'Analytics zeta reporting', group: project_parent, developers: user)
  end

  let(:query) do
    get_graphql_query_as_string('explore/analytics_dashboards/graphql/search_namespaces_global.query.graphql')
  end

  let(:returned_group_paths) { graphql_data.dig('groups', 'nodes').pluck('fullPath') }
  let(:returned_project_paths) { graphql_data.dig('projects', 'nodes').pluck('fullPath') }

  before do
    post_graphql(query, current_user: user, variables: { 'search' => 'zeta' })
  end

  it 'returns only groups the user is a member of' do
    expect(returned_group_paths).to contain_exactly(closest_group.full_path, distant_group.full_path)
  end

  it 'ranks the closest group match first' do
    expect(returned_group_paths).to eq([closest_group.full_path, distant_group.full_path])
  end

  # `Query.projects` sorts by similarity whenever `search` is given, so the document
  # passes no sort on this half.
  it 'ranks the closest project match first without an explicit sort' do
    expect(returned_project_paths).to eq([closest_project.full_path, distant_project.full_path])
  end
end
