# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting a tree in a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { project.owner }
  let(:path) { "" }
  let(:ref) { "master" }
  let(:fields) do
    <<~QUERY
      tree(path:"#{path}", ref:"#{ref}") {
        #{all_graphql_fields_for('tree'.classify)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('repository', {}, fields)
    )
  end

  context 'when path does not exist' do
    let(:path) { "testing123" }

    it 'returns empty tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['submodules']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['blobs']['edges']).to eq([])
    end

    it 'returns null commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['last_commit']).to be_nil
    end
  end

  context 'when ref does not exist' do
    let(:ref) { "testing123" }

    it 'returns empty tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['submodules']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['blobs']['edges']).to eq([])
    end

    it 'returns null commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['last_commit']).to be_nil
    end
  end

  context 'when ref and path exist' do
    it 'returns tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']).to be_present
    end

    it 'returns blobs, subtrees and submodules inside tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges'].size).to be > 0
      expect(graphql_data['project']['repository']['tree']['blobs']['edges'].size).to be > 0
      expect(graphql_data['project']['repository']['tree']['submodules']['edges'].size).to be > 0
    end

    it 'returns tree latest commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['lastCommit']).to be_present
    end
  end

  context 'when current user is nil' do
    it 'returns empty project' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']).to be(nil)
    end
  end
end
