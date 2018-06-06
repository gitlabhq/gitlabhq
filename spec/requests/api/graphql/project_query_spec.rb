require 'spec_helper'

describe 'getting project information' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { create(:user) }

  let(:query) do
    graphql_query_for('project', 'fullPath' => project.full_path)
  end

  context 'when the user has access to the project' do
    before do
      project.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it 'includes the project' do
      expect(graphql_data['project']).not_to be_nil
    end

    it_behaves_like 'a working graphql query'
  end

  context 'when the user does not have access to the project' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns an empty field' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to be_nil
    end

    it_behaves_like 'a working graphql query'
  end
end
