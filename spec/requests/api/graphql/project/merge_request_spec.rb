# frozen_string_literal: true

require 'spec_helper'

describe 'getting merge request information nested in a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:current_user) { create(:user) }
  let(:merge_request_graphql_data) { graphql_data['project']['mergeRequest'] }
  let!(:merge_request) { create(:merge_request, source_project: project) }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('mergeRequest', iid: merge_request.iid.to_s)
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

  context 'permissions on the merge request' do
    it 'includes the permissions for the current user on a public project' do
      expected_permissions = {
        'readMergeRequest' => true,
        'adminMergeRequest' => false,
        'createNote' => true,
        'pushToSourceBranch' => false,
        'removeSourceBranch' => false,
        'cherryPickOnCurrentMergeRequest' => false,
        'revertOnCurrentMergeRequest' => false,
        'updateMergeRequest' => false
      }
      post_graphql(query, current_user: current_user)

      permission_data = merge_request_graphql_data['userPermissions']

      expect(permission_data).to be_present
      expect(permission_data).to eq(expected_permissions)
    end
  end

  context 'when the user does not have access to the merge request' do
    let(:project) { create(:project, :public, :repository) }

    it 'returns nil' do
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(merge_request_graphql_data).to be_nil
    end
  end

  context 'when there are pipelines' do
    before do
      create(
        :ci_pipeline,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )
      merge_request.update_head_pipeline
    end

    it 'has a head pipeline' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data['headPipeline']).to be_present
    end

    it 'has pipeline connections' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data['pipelines']['edges'].size).to eq(1)
    end
  end

  context 'when limiting the number of results' do
    let(:merge_requests_graphql_data) { graphql_data['project']['mergeRequests']['edges'] }

    let!(:merge_requests) do
      [
        create(:merge_request, source_project: project, source_branch: 'branch-1'),
        create(:merge_request, source_project: project, source_branch: 'branch-2'),
        create(:merge_request, source_project: project, source_branch: 'branch-3')
      ]
    end

    let(:fields) do
      <<~QUERY
      edges {
        node {
          iid,
          title
        }
      }
      QUERY
    end

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        "mergeRequests(first: 2) { #{fields} }"
      )
    end

    it 'returns the correct number of results' do
      post_graphql(query, current_user: current_user)

      expect(merge_requests_graphql_data.size).to eq 2
    end
  end
end
