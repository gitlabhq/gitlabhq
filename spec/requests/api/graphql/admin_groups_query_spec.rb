# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups for the admin area', :with_license, feature_category: :groups_and_projects do
  include GraphqlHelpers

  it_behaves_like 'groups query' do
    let(:field_name) { :adminGroups }
    let(:group_fields) { all_graphql_fields_for('Group', excluded: %w[runners ciQueueingHistory securityCategories]) }
    let(:fields) do
      "nodes {
        ... on Group {
          #{group_fields}
        }
      }
      count"
    end
  end

  describe 'sorting by similarity' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:closest_match) { create(:group, :private, name: 'zeta') }
    let_it_be(:distant_match) { create(:group, :private, name: 'analytics zeta reporting') }

    # An admin's default scope is every group, which is not bounded by membership,
    # so `similarity` is refused rather than scored across all namespaces.
    it 'falls back to id_desc', :enable_admin_mode do
      post_graphql(
        graphql_query_for(:admin_groups, { search: 'zeta', sort: 'similarity' }, 'nodes { fullPath }'),
        current_user: admin
      )

      expect(graphql_data.dig('adminGroups', 'nodes').pluck('fullPath'))
        .to eq([distant_match.full_path, closest_match.full_path])
    end
  end
end
