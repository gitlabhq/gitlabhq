# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying for import source users', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let(:current_user) { user }

  def query
    graphql_query_for(
      'namespace',
      { 'fullPath' => namespace.full_path },
      <<~IMPORT_SOURCE_USERS
        importSourceUsers {
          nodes {
            id
          }
        }
      IMPORT_SOURCE_USERS
    )
  end

  describe 'for a group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:import_source_users) { create_list(:import_source_user, 3, namespace: group) }
    let_it_be(:namespace) { group }

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when user is authorized to query the import source users' do
      before_all do
        group.add_owner(user)
      end

      it 'returns import source users' do
        response_ids = graphql_data_at('namespace', 'importSourceUsers', 'nodes', 'id')
        expected_ids = import_source_users.map { |u| global_id_of(u).to_s }

        expect(response_ids).to match_array(expected_ids)
      end
    end

    context 'when user is not authorized to query for the import source users' do
      before_all do
        group.add_maintainer(user)
      end

      it 'does not return import source users' do
        expect(graphql_data.dig('namespace', 'importSourceUsers')).to eq(nil)
      end
    end
  end

  describe 'for user namespace' do
    let_it_be(:namespace) { create(:namespace, owner: user) }
    let_it_be(:import_source_users) { create_list(:import_source_user, 3, namespace: namespace) }

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when user is authorized to query the import source users' do
      it 'returns import source users' do
        response_ids = graphql_data.dig('namespace', 'importSourceUsers', 'nodes').pluck('id')
        expected_ids = import_source_users.map { |u| u.to_global_id.to_s }

        expect(response_ids).to match_array(expected_ids)
      end
    end

    context 'when user is not authorized to query for the import source users' do
      let(:current_user) { create(:user) }

      it 'does not return import source users' do
        expect(graphql_data['namespace']).to eq(nil)
      end
    end
  end
end
