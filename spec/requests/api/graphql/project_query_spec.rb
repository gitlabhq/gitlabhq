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
    end

    it 'includes the project' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).not_to be_nil
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    context 'when requesting a nested merge request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:merge_request_graphql_data) { graphql_data['project']['mergeRequest'] }

      let(:query) do
        graphql_query_for(
          'project',
          { 'fullPath' => project.full_path },
          query_graphql_field('mergeRequest', iid: merge_request.iid)
        )
      end

      it_behaves_like 'a working graphql query' do
        before do
          post_graphql(query, current_user: current_user)
        end
      end

      it 'contains merge request information' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).not_to be_nil
      end

      # This is a field coming from the `MergeRequestPresenter`
      it 'includes a web_url' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data['webUrl']).to be_present
      end

      context 'when the user does not have access to the merge request' do
        let(:project) { create(:project, :public, :repository) }

        it 'returns nil' do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

          post_graphql(query)

          expect(merge_request_graphql_data).to be_nil
        end
      end
    end
  end

  context 'when the user does not have access to the project' do
    it 'returns an empty field' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to be_nil
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end
end
