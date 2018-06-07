require 'spec_helper'

describe 'getting merge request information' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:current_user) { create(:user) }

  let(:query) do
    attributes = {
      'fullPath' => merge_request.project.full_path,
      'iid' => merge_request.iid
    }
    graphql_query_for('mergeRequest',  attributes)
  end

  context 'when the user has access to the merge request' do
    before do
      project.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it 'returns the merge request' do
      expect(graphql_data['mergeRequest']).not_to be_nil
    end

    # This is a field coming from the `MergeRequestPresenter`
    it 'includes a web_url' do
      expect(graphql_data['mergeRequest']['webUrl']).to be_present
    end

    it_behaves_like 'a working graphql query'
  end

  context 'when the user does not have access to the merge request' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns an empty field' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['mergeRequest']).to be_nil
    end

    it_behaves_like 'a working graphql query'
  end
end
