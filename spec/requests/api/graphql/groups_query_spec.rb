# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups', :with_license, feature_category: :groups_and_projects do
  include GraphqlHelpers

  it_behaves_like 'groups query'

  # Exercised through the schema rather than the resolver, because the argument
  # arrives as a String only after GraphQL coercion.
  describe 'sorting by similarity' do
    let_it_be(:user) { create(:user) }
    # `zeta` is the closer match but sorts last by name and has the lower ID, so
    # this distinguishes similarity from both the `name_asc` default and the
    # `id_desc` fallback.
    let_it_be(:closest_match) { create(:group, :private, name: 'zeta', developers: user) }
    let_it_be(:distant_match) { create(:group, :private, name: 'analytics zeta reporting', developers: user) }

    let(:returned_paths) { graphql_data.dig('groups', 'nodes').pluck('fullPath') }

    def run_query(args)
      post_graphql(graphql_query_for(:groups, args, 'nodes { fullPath }'), current_user: user)
    end

    it 'ranks the closest match first' do
      run_query({ search: 'zeta', sort: 'similarity', all_available: false })

      expect(returned_paths).to eq([closest_match.full_path, distant_match.full_path])
    end

    it 'falls back to id_desc when the scope is not bounded by membership' do
      run_query({ search: 'zeta', sort: 'similarity', all_available: true })

      expect(returned_paths).to eq([distant_match.full_path, closest_match.full_path])
    end
  end
end
