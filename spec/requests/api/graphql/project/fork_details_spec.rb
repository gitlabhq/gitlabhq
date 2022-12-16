# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project fork details', feature_category: :source_code_management do
  include GraphqlHelpers
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :public, :repository_private, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project]) }
  let_it_be(:forked_project) { fork_project(project, current_user, repository: true) }

  let(:queried_project) { forked_project }

  let(:query) do
    graphql_query_for(:project,
      { full_path: queried_project.full_path }, <<~QUERY
      forkDetails(ref: "feature"){
        ahead
        behind
      }
      QUERY
    )
  end

  it 'returns fork details' do
    post_graphql(query, current_user: current_user)

    expect(graphql_data['project']['forkDetails']).to eq(
      { 'ahead' => 1, 'behind' => 29 }
    )
  end

  context 'when a project is not a fork' do
    let(:queried_project) { project }

    it 'does not return fork details' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['forkDetails']).to be_nil
    end
  end

  context 'when a user cannot read the code' do
    let_it_be(:current_user) { create(:user) }

    before do
      forked_project.update!({
                               repository_access_level: 'private',
                               merge_requests_access_level: 'private'
                             })
    end

    it 'does not return fork details' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['forkDetails']).to be_nil
    end
  end
end
