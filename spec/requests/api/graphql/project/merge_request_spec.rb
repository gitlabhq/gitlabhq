# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request information nested in a project' do
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

  it 'includes author' do
    post_graphql(query, current_user: current_user)

    expect(merge_request_graphql_data['author']['username']).to eq(merge_request.author.username)
  end

  it 'includes diff stats' do
    be_natural = an_instance_of(Integer).and(be >= 0)

    post_graphql(query, current_user: current_user)

    sums = merge_request_graphql_data['diffStats'].reduce([0, 0, 0]) do |(a, d, c), node|
      a_, d_ = node.values_at('additions', 'deletions')
      [a + a_, d + d_, c + a_ + d_]
    end

    expect(merge_request_graphql_data).to include(
      'diffStats' => all(a_hash_including('path' => String, 'additions' => be_natural, 'deletions' => be_natural)),
      'diffStatsSummary' => a_hash_including(
        'fileCount' => merge_request.diff_stats.count,
        'additions' => be_natural,
        'deletions' => be_natural,
        'changes' => be_natural
      )
    )

    # diff_stats is consistent with summary
    expect(merge_request_graphql_data['diffStatsSummary']
      .values_at('additions', 'deletions', 'changes')).to eq(sums)

    # diff_stats_summary is internally consistent
    expect(merge_request_graphql_data['diffStatsSummary']
      .values_at('additions', 'deletions').sum)
      .to eq(merge_request_graphql_data.dig('diffStatsSummary', 'changes'))
      .and be_positive
  end

  context 'requesting a specific diff stat' do
    let(:diff_stat) { merge_request.diff_stats.first }

    let(:query) do
      graphql_query_for(:project, { full_path: project.full_path },
        query_graphql_field(:merge_request, { iid: merge_request.iid.to_s }, [
          query_graphql_field(:diff_stats, { path: diff_stat.path }, all_graphql_fields_for('DiffStats'))
        ])
      )
    end

    it 'includes only the requested stats' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data).to include(
        'diffStats' => contain_exactly(
          a_hash_including('path' => diff_stat.path, 'additions' => diff_stat.additions, 'deletions' => diff_stat.deletions)
        )
      )
    end
  end

  it 'includes correct mergedAt value when merged' do
    time = 1.week.ago
    merge_request.mark_as_merged
    merge_request.metrics.update_columns(merged_at: time)

    post_graphql(query, current_user: current_user)
    retrieved = merge_request_graphql_data['mergedAt']

    expect(Time.zone.parse(retrieved)).to be_within(1.second).of(time)
  end

  it 'includes nil mergedAt value when not merged' do
    post_graphql(query, current_user: current_user)
    retrieved = merge_request_graphql_data['mergedAt']

    expect(retrieved).to be_nil
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
        'updateMergeRequest' => false,
        'canMerge' => false
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

  context 'when merge request is cannot_be_merged_rechecking' do
    before do
      merge_request.update!(merge_status: 'cannot_be_merged_rechecking')
    end

    it 'returns checking' do
      post_graphql(query, current_user: current_user)
      expect(merge_request_graphql_data['mergeStatus']).to eq('checking')
    end
  end
end
