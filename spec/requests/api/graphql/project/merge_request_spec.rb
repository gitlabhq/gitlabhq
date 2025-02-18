# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request information nested in a project', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }

  let(:merge_request_graphql_data) { graphql_data_at(:project, :merge_request) }
  let(:mr_fields) { all_graphql_fields_for('MergeRequest', max_depth: 1) }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:merge_request, { iid: merge_request.iid.to_s }, mr_fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    # we exclude Project.pipeline because it needs arguments,
    # codequalityReportsComparer because it is behind a feature flag
    # and runners because the user is not an admin and therefore has no access
    # and inboundAllowlistCount, groupsAllowlistCount, groupAllowlistAutopopulatedIds,
    #   inboundAllowlistAutopopulatedIds the user has no access
    # mergeTrains because it is a licensed feature
    let(:excluded) do
      %w[jobs pipeline runners codequalityReportsComparer
        mlModels inboundAllowlistCount groupsAllowlistCount mergeTrains ciJobTokenAuthLogs mlExperiments
        groupAllowlistAutopopulatedIds inboundAllowlistAutopopulatedIds]
    end

    let(:mr_fields) { all_graphql_fields_for('MergeRequest', excluded: excluded) }

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

  context 'when selecting author' do
    let(:mr_fields) { 'author { username }' }

    it 'includes author' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data['author']['username']).to eq(merge_request.author.username)
    end
  end

  context 'when the merge_request has reviewers' do
    let(:mr_fields) do
      <<~SELECT
      reviewers { nodes { id username } }
      participants { nodes { id username } }
      SELECT
    end

    before do
      merge_request.reviewers << create_list(:user, 2)
    end

    it 'includes reviewers' do
      expected = merge_request.reviewers.map do |r|
        a_graphql_entity_for(r, :username)
      end

      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:project, :merge_request, :reviewers, :nodes)).to match_array(expected)
      expect(graphql_data_at(:project, :merge_request, :participants, :nodes)).to include(*expected)
    end
  end

  context 'when the merge_request has committers' do
    let(:mr_fields) do
      <<~SELECT
      committers { nodes { id username } }
      SELECT
    end

    it 'includes committers' do
      expected = merge_request.committers.map do |r|
        a_hash_including('id' => global_id_of(r), 'username' => r.username)
      end

      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:project, :merge_request, :committers, :nodes)).to match_array(expected)
    end
  end

  describe 'diffStats' do
    let(:mr_fields) do
      <<~FIELDS
      diffStats { #{all_graphql_fields_for('DiffStats')} }
      diffStatsSummary { #{all_graphql_fields_for('DiffStatsSummary')} }
      FIELDS
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

    context 'when requesting a specific diff stat' do
      let(:diff_stat) { merge_request.diff_stats.first }

      let(:mr_fields) do
        query_graphql_field(
          :diff_stats,
          { path: diff_stat.path },
          all_graphql_fields_for('DiffStats')
        )
      end

      it 'includes only the requested stats' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_graphql_data).to include(
          'diffStats' => contain_exactly(
            a_hash_including(
              'path' => diff_stat.path,
              'additions' => diff_stat.additions,
              'deletions' => diff_stat.deletions
            )
          )
        )
      end
    end

    context 'when a path includes a non UTF-8 character' do
      let_it_be(:diff_stats) do
        diff_stat = Gitaly::DiffStats.new(
          additions: 10,
          deletions: 15,
          path: (+'romualdatchadé.yml').force_encoding(Encoding::ASCII_8BIT)
        )

        Gitlab::Git::DiffStatsCollection.new([diff_stat])
      end

      before do
        allow_any_instance_of(MergeRequest).to receive(:diff_stats).and_return(diff_stats) # rubocop:disable RSpec/AnyInstanceOf -- Targeting simply next_instance isn't sufficient

        post_graphql(query, current_user: current_user)
      end

      it 'does not raise an error' do
        expect(graphql_errors).to be_nil
      end

      it 'returns the expected UTF-8 path' do
        expect(merge_request_graphql_data['diffStats']).to include(a_hash_including('path' => 'romualdatchadé.yml'))
      end
    end
  end

  describe 'mergedAt' do
    let(:merged_at) { merge_request_graphql_data['mergedAt'] }

    subject(:graphql_query) { post_graphql(query, current_user: current_user) }

    context 'when the merge request is merged' do
      let_it_be(:time) { 1.week.ago }

      before do
        merge_request.mark_as_merged
        merge_request.metrics.update!(merged_at: time)
      end

      it 'includes correct mergedAt value' do
        graphql_query

        expect(Time.zone.parse(merged_at)).to be_within(1.second).of(time)
      end
    end

    context 'when the merge request is not merged' do
      it 'includes nil mergedAt value' do
        graphql_query

        expect(merged_at).to be_nil
      end
    end
  end

  describe 'closedAt' do
    let(:closed_at) { merge_request_graphql_data['closedAt'] }

    subject(:graphql_query) { post_graphql(query, current_user: current_user) }

    context 'when the merge request is closed' do
      let_it_be(:time) { 1.week.ago }

      before do
        merge_request.close!
        merge_request.metrics.update!(latest_closed_at: time)
      end

      it 'includes correct closedAt value' do
        graphql_query

        expect(Time.zone.parse(closed_at)).to be_within(1.second).of(time)
      end
    end

    context 'when the merge request is not closed' do
      it 'includes nil closedAt value' do
        graphql_query

        expect(closed_at).to be_nil
      end
    end
  end

  describe 'permissions on the merge request' do
    let(:mr_fields) do
      "userPermissions { #{all_graphql_fields_for('MergeRequestPermissions')} }"
    end

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
        'canMerge' => false,
        'canApprove' => false
      }
      post_graphql(query, current_user: current_user)

      permission_data = merge_request_graphql_data['userPermissions']

      expect(permission_data).to be_present
      expect(permission_data).to eq(expected_permissions)
    end
  end

  context 'when the user does not have access to the merge request' do
    it 'returns nil' do
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(merge_request_graphql_data).to be_nil
    end
  end

  context 'when there are pipelines' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )
    end

    let(:mr_fields) do
      <<~FIELDS
      headPipeline { id }
      pipelines { nodes { id } }
      FIELDS
    end

    before do
      merge_request.update_head_pipeline
    end

    it 'has a head pipeline' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data['headPipeline']).to be_present
    end

    it 'has pipeline connections' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_graphql_data['pipelines']['nodes']).to be_one
    end
  end

  context 'when limiting the number of results' do
    let(:merge_requests_graphql_data) { graphql_data_at(:project, :merge_requests, :edges) }

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
      create(:merge_request, source_project: project, source_branch: 'branch-1')
      create(:merge_request, source_project: project, source_branch: 'branch-2')
      create(:merge_request, source_project: project, source_branch: 'branch-3')

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

  # see: https://gitlab.com/gitlab-org/gitlab/-/issues/297358
  context 'when the notes have been preloaded (by participants)' do
    let(:query) do
      <<~GQL
      query($path: ID!) {
        project(fullPath: $path) {
          mrs: mergeRequests(first: 1) {
            nodes {
              participants { nodes { id } }
              notes(first: 1) {
                pageInfo { endCursor hasPreviousPage hasNextPage }
                nodes { id }
              }
            }
          }
        }
      }
      GQL
    end

    before do
      create_list(:note_on_merge_request, 3, project: project, noteable: merge_request)
    end

    it 'does not error' do
      post_graphql(
        query,
        current_user: current_user,
        variables: { path: project.full_path }
      )

      expect(graphql_data_at(:project, :mrs, :nodes, :notes, :pageInfo)).to contain_exactly a_hash_including(
        'endCursor' => String,
        'hasNextPage' => true,
        'hasPreviousPage' => false
      )
    end
  end

  shared_examples 'when requesting information about MR interactions' do
    let_it_be(:user) { create(:user) }

    let(:selected_fields) { all_graphql_fields_for('UserMergeRequestInteraction') }

    let(:mr_fields) do
      query_nodes(
        field,
        query_graphql_field(:merge_request_interaction, nil, selected_fields)
      )
    end

    def interaction_data
      graphql_data_at(:project, :merge_request, field, :nodes, :merge_request_interaction)
    end

    context 'when the user is not assigned' do
      it 'returns null data' do
        post_graphql(query)

        expect(interaction_data).to be_empty
      end
    end

    context 'when the user is a reviewer, but has not reviewed' do
      before do
        project.add_guest(user)
        assign_user(user)
      end

      it 'returns falsey values' do
        post_graphql(query)

        expect(interaction_data).to contain_exactly a_hash_including(
          'canMerge' => false,
          'canUpdate' => can_update,
          'reviewState' => unreviewed,
          'reviewed' => false,
          'approved' => false
        )
      end
    end

    context 'when the user has interacted' do
      before do
        project.add_maintainer(user)
        assign_user(user)
        r = merge_request.merge_request_reviewers.find_or_create_by!(reviewer: user)
        r.update!(state: :approved)
        merge_request.approved_by_users << user
      end

      it 'returns appropriate data' do
        post_graphql(query)
        enum = ::Types::MergeRequestReviewStateEnum.values['APPROVED']

        expect(interaction_data).to contain_exactly a_hash_including(
          'canMerge' => true,
          'canUpdate' => true,
          'reviewState' => enum.graphql_name,
          'reviewed' => false,
          'approved' => true
        )
      end
    end

    describe 'scalability' do
      let_it_be(:other_users) { create_list(:user, 3) }

      let(:unreviewed) do
        { 'reviewState' => 'UNREVIEWED' }
      end

      let(:reviewed) do
        { 'reviewState' => 'REVIEWED' }
      end

      shared_examples 'scalable query for interaction fields' do
        before do
          ([user] + other_users).each { project.add_guest(_1) }
        end

        it 'does not suffer from N+1' do
          assign_user(user)
          merge_request.merge_request_reviewers
            .find_or_create_by!(reviewer: user)
            .update!(state: 'reviewed')

          baseline = ActiveRecord::QueryRecorder.new do
            post_graphql(query)
          end

          expect(interaction_data).to contain_exactly(include(reviewed))

          other_users.each do |user|
            assign_user(user)
            merge_request.merge_request_reviewers.find_or_create_by!(reviewer: user)
          end

          expect { post_graphql(query) }.not_to exceed_query_limit(baseline)

          expect(interaction_data).to contain_exactly(
            include(unreviewed),
            include(unreviewed),
            include(unreviewed),
            include(reviewed)
          )
        end
      end

      context 'when selecting only known scalable fields' do
        let(:not_scalable) { %w[canUpdate canMerge] }
        let(:selected_fields) do
          all_graphql_fields_for('UserMergeRequestInteraction', excluded: not_scalable)
        end

        it_behaves_like 'scalable query for interaction fields'
      end

      context 'when selecting all fields' do
        before do
          pending "See: https://gitlab.com/gitlab-org/gitlab/-/issues/322549"
        end

        let(:selected_fields) { all_graphql_fields_for('UserMergeRequestInteraction') }

        it_behaves_like 'scalable query for interaction fields'
      end
    end
  end

  it_behaves_like 'when requesting information about MR interactions' do
    let(:field) { :reviewers }
    let(:unreviewed) { 'UNREVIEWED' }
    let(:can_update) { false }

    def assign_user(user)
      merge_request.merge_request_reviewers.create!(reviewer: user)
    end
  end

  it_behaves_like 'when requesting information about MR interactions' do
    let(:field) { :assignees }
    let(:unreviewed) { nil }
    let(:can_update) { true } # assignees can update MRs

    def assign_user(user)
      merge_request.assignees << user
    end
  end

  context 'when selecting `awardEmoji`' do
    let_it_be(:award_emoji) { create(:award_emoji, awardable: merge_request, user: current_user) }

    let(:mr_fields) do
      <<~QUERY
      awardEmoji {
        nodes {
          user {
            username
          }
          name
        }
      }
      QUERY
    end

    it 'includes award emojis' do
      post_graphql(query, current_user: current_user)

      response = merge_request_graphql_data['awardEmoji']['nodes']

      expect(response.length).to eq(1)
      expect(response.first['user']['username']).to eq(current_user.username)
      expect(response.first['name']).to eq(award_emoji.name)
    end
  end
end
