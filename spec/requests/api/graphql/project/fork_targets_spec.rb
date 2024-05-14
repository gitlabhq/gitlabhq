# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of fork targets for a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:another_group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:user) { create(:user, developer_of: project, owner_of: [group, another_group]) }

  let(:current_user) { user }
  let(:fields) do
    <<~GRAPHQL
      forkTargets{
        nodes { id name fullPath visibility }
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

    it 'returns fork targets for the project' do
      expect(graphql_data.dig('project', 'forkTargets', 'nodes')).to match_array(
        [user.namespace, project.namespace, another_group].map do |target|
          hash_including(
            {
              'id' => target.to_global_id.to_s,
              'name' => target.name,
              'fullPath' => target.full_path,
              'visibility' => target.visibility
            }
          )
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
