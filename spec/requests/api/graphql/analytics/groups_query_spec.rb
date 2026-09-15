# frozen_string_literal: true

require 'spec_helper'

# Exercises the query document the analytics group filter actually ships, so
# changing its `allAvailable` or `sort` arguments fails here rather than in production.
RSpec.describe 'analyticsGetGroups query', feature_category: :custom_dashboards_foundation do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:member_group) { create(:group, :private, name: 'Analytics members') }
  let_it_be(:public_non_member_group) { create(:group, :public, name: 'Analytics public') }

  let(:query) { get_graphql_query_as_string('analytics/shared/graphql/groups.query.graphql') }
  let(:variables) { { 'search' => 'Analytics', 'first' => 20 } }
  let(:returned_paths) { graphql_data.dig('groups', 'nodes').pluck('fullPath') }

  before_all do
    member_group.add_developer(user)
  end

  before do
    post_graphql(query, current_user: user, variables: variables)
  end

  it 'returns only groups the user is a member of', :aggregate_failures do
    expect(returned_paths).to include(member_group.full_path)
    expect(returned_paths).not_to include(public_non_member_group.full_path)
  end

  context 'when sorting by similarity' do
    # `Zeta` is the closer match for `zeta`, but sorts last by name and is created
    # first, so this fails under both the `name_asc` default and the `id_desc` fallback.
    let_it_be(:closest_match) { create(:group, :private, name: 'Zeta', developers: user) }
    let_it_be(:distant_match) { create(:group, :private, name: 'Analytics zeta reporting', developers: user) }

    let(:variables) { { 'search' => 'zeta', 'first' => 20, 'sort' => 'similarity' } }

    it 'ranks the closest match first' do
      expect(returned_paths).to eq([closest_match.full_path, distant_match.full_path])
    end
  end
end
