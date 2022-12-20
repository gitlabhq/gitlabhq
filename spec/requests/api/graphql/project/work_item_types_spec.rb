# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of work item types for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_developer(developer)
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
      'project',
      { 'fullPath' => project.full_path },
      fields
    )
  end

  context 'when user has access to the project' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all default work item types' do
      expect(graphql_data.dig('project', 'workItemTypes', 'nodes')).to match_array(
        WorkItems::Type.default.map do |type|
          hash_including('id' => type.to_global_id.to_s, 'name' => type.name, 'iconName' => type.icon_name)
        end
      )
    end
  end

  context "when user doesn't have access to the project" do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'does not return the project' do
      expect(graphql_data).to eq('project' => nil)
    end
  end
end
