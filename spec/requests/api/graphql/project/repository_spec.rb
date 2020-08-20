# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting a repository in a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { project.owner }
  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('repository'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('repository', {}, fields)
    )
  end

  it 'returns repository' do
    post_graphql(query, current_user: current_user)

    expect(graphql_data['project']['repository']).to be_present
  end

  context 'as a non-authorized user' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to be(nil)
    end
  end

  context 'when the repository is only accessible to members' do
    let(:project) do
      create(:project, :public, :repository, repository_access_level: ProjectFeature::PRIVATE)
    end

    it 'returns a repository for the owner' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']).not_to be_nil
    end

    it 'returns nil for the repository for other users' do
      post_graphql(query, current_user: create(:user))

      expect(graphql_data['project']['repository']).to be_nil
    end

    it 'returns nil for the repository for other users' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']['repository']).to be_nil
    end
  end
end
