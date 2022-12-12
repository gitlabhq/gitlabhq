# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of work item types for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  before_all do
    group.add_developer(developer)
  end

  let(:current_user) { developer }

  let(:fields) do
    <<~GRAPHQL
      workItemTypes{
        nodes { id name iconName }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      fields
    )
  end

  context 'when user has access to the group' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all default work item types' do
      expect(graphql_data.dig('group', 'workItemTypes', 'nodes')).to match_array(
        WorkItems::Type.default.map do |type|
          hash_including('id' => type.to_global_id.to_s, 'name' => type.name, 'iconName' => type.icon_name)
        end
      )
    end
  end

  context "when user doesn't have access to the group" do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'does not return the group' do
      expect(graphql_data).to eq('group' => nil)
    end
  end
end
