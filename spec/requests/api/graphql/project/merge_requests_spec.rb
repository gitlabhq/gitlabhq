# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request listings nested in a project', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:group_label) { create(:group_label, group: group) }

  let_it_be_with_reload(:merge_request_a) do
    create(:labeled_merge_request, :unique_branches, source_project: project, labels: [label, group_label],
      reviewers: [current_user])
  end

  let_it_be(:merge_request_b) do
    create(:merge_request, :closed, :unique_branches, source_project: project, reviewers: [current_user, create(:user)])
  end

  let_it_be(:merge_request_c) do
    create(:labeled_merge_request, :closed, :unique_branches, source_project: project, labels: [label, group_label])
  end

  let_it_be(:merge_request_d) do
    create(:merge_request, :locked, :unique_branches, source_project: project)
  end

  let_it_be(:merge_request_e) do
    create(:merge_request, :unique_branches, source_project: project)
  end

  let(:all_merge_requests) do
    [merge_request_a, merge_request_b, merge_request_c, merge_request_d, merge_request_e]
  end

  let(:results) { graphql_data.dig('project', 'mergeRequests', 'nodes') }

  let(:search_params) { nil }

  def query_merge_requests(fields)
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:merge_requests, fields, args: search_params)
    )
  end

  it_behaves_like 'a working graphql query' do
    # we exclude codequalityReportsComparer because it is behind feature flag
    let(:excluded) { %w[codequalityReportsComparer] }

    let(:query) do
      query_merge_requests(all_graphql_fields_for('MergeRequest', max_depth: 2, excluded: excluded))
    end

    before do
      # We cannot disable SQL query limiting here, since the transaction does not
      # begin until we enter the controller.
      headers = {
        'X-GITLAB-DISABLE-SQL-QUERY-LIMIT' => '224,https://gitlab.com/gitlab-org/gitlab/-/issues/469250'
      }

      post_graphql(query, current_user: current_user, headers: headers)
    end
  end

  # The following tests are needed to guarantee that we have correctly annotated
  # all the gitaly calls.  Selecting combinations of fields may mask this due to
  # memoization.
  context 'when requesting a single field' do
    let_it_be(:fresh_mr) { create(:merge_request, :unique_branches, source_project: project) }

    let(:search_params) { { iids: [fresh_mr.iid.to_s] } }
    let(:graphql_data) do
      GitlabSchema.execute(query, context: { current_user: current_user }).to_h['data']
    end

    before do
      project.repository.expire_branches_cache
    end

    context 'when selecting any single scalar field' do
      where(:field) do
        scalar_fields_of('MergeRequest').map { |name| [name] }
      end

      with_them do
        let(:query) do
          query_merge_requests([:iid, field].uniq)
        end

        it 'selects the correct MR' do
          expect(results).to contain_exactly(a_hash_including('iid' => fresh_mr.iid.to_s))
        end
      end
    end

    context 'when selecting any single nested field' do
      where(:field, :subfield, :is_connection) do
        nested_fields_of('MergeRequest').flat_map do |name, field|
          type = field_type(field)
          is_connection = type.graphql_name.ends_with?('Connection')
          type = field_type(type.fields['nodes']) if is_connection

          type.fields
            .select { |_, field| !nested_fields?(field) && !required_arguments?(field) }
            .map(&:first)
            .map { |subfield| [name, subfield, is_connection] }
        end
      end

      with_them do
        let(:query) do
          fld = is_connection ? query_graphql_field(:nodes, nil, [subfield]) : subfield
          query_merge_requests([:iid, query_graphql_field(field, nil, [fld])])
        end

        it 'selects the correct MR' do
          expect(results).to contain_exactly(a_hash_including('iid' => fresh_mr.iid.to_s))
        end
      end
    end
  end

  shared_examples 'when searching with parameters' do
    let(:query) do
      query_merge_requests('iid title')
    end

    let(:expected) do
      mrs.map { |mr| a_hash_including('iid' => mr.iid.to_s, 'title' => mr.title) }
    end

    it 'finds the right mrs' do
      post_graphql(query, current_user: current_user)

      expect(results).to match_array(expected)
    end
  end

  context 'when there are no search params' do
    let(:search_params) { nil }
    let(:mrs) { [merge_request_a, merge_request_b, merge_request_c, merge_request_d, merge_request_e] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when the search params do not match anything' do
    let(:search_params) { { iids: %w[foo bar baz] } }
    let(:mrs) { [] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by iids' do
    let(:search_params) { { iids: mrs.map(&:iid).map(&:to_s) } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by state' do
    let(:search_params) { { state: :closed } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by source_branch' do
    let(:search_params) { { source_branches: mrs.map(&:source_branch) } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by target_branch' do
    let(:search_params) { { target_branches: mrs.map(&:target_branch) } }
    let(:mrs) { [merge_request_a, merge_request_d] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by label' do
    let(:search_params) { { labels: [label.title] } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when searching by update time' do
    let(:start_time) { 10.days.ago }
    let(:cutoff) { start_time + 36.hours }

    before do
      all_merge_requests.each_with_index do |mr, i|
        mr.updated_at = start_time + i.days
        mr.save!(touch: false)
      end
    end

    context 'when searching by updated_after' do
      let(:search_params) { { updated_after: cutoff } }
      let(:mrs) { all_merge_requests[2..] }

      it_behaves_like 'when searching with parameters'
    end

    context 'when searching by updated_before' do
      let(:search_params) { { updated_before: cutoff } }
      let(:mrs) { all_merge_requests[0..1] }

      it_behaves_like 'when searching with parameters'
    end

    context 'when searching by updated_before and updated_after' do
      let(:search_params) { { updated_after: cutoff, updated_before: cutoff + 2.days } }
      let(:mrs) { all_merge_requests[2..3] }

      it_behaves_like 'when searching with parameters'
    end
  end

  context 'when searching by combination' do
    let(:search_params) { { state: :closed, labels: [label.title] } }
    let(:mrs) { [merge_request_c] }

    it_behaves_like 'when searching with parameters'
  end

  context 'when requesting not the only assigned reviewer' do
    let(:search_params) do
      {
        iids: [merge_request_a.iid.to_s, merge_request_b.iid.to_s],
        not: { reviewer_username: current_user.username, only_reviewer: true }
      }
    end

    let(:extra_iid_for_second_query) { merge_request_c.iid.to_s }
    let(:requested_fields) { [:iid] }
    let(:mrs) { [merge_request_b] }

    def execute_query
      query = query_merge_requests(requested_fields)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'when searching with parameters'

    include_examples 'N+1 query check'
  end

  context 'when requesting `approved_by`' do
    let(:search_params) { { iids: [merge_request_a.iid.to_s, merge_request_b.iid.to_s] } }
    let(:extra_iid_for_second_query) { merge_request_c.iid.to_s }
    let(:requested_fields) { query_graphql_field(:approved_by, nil, query_graphql_field(:nodes, nil, [:username])) }

    def execute_query
      query = query_merge_requests(requested_fields)
      post_graphql(query, current_user: current_user)
    end

    it 'exposes approver username' do
      merge_request_a.approved_by_users << current_user

      execute_query

      user_data = { 'username' => current_user.username }
      expect(results).to include(a_hash_including('approvedBy' => { 'nodes' => array_including(user_data) }))
    end

    include_examples 'N+1 query check'
  end

  describe 'fields' do
    let(:requested_fields) { nil }
    let(:extra_iid_for_second_query) { merge_request_c.iid.to_s }
    let(:search_params) { { iids: [merge_request_a.iid.to_s, merge_request_b.iid.to_s] } }

    def execute_query
      query = query_merge_requests(requested_fields)
      post_graphql(query, current_user: current_user)
    end

    context 'when requesting `commit_count`' do
      let(:merge_request_with_commits) { create(:merge_request, source_project: project) }
      let(:search_params) { { iids: [merge_request_a.iid.to_s, merge_request_with_commits.iid.to_s] } }
      let(:requested_fields) { [:iid, :commit_count] }

      it 'exposes `commit_count`' do
        execute_query

        expect(results).to match_array [
          { "iid" => merge_request_a.iid.to_s, "commitCount" => 0 },
          { "iid" => merge_request_with_commits.iid.to_s, "commitCount" => 29 }
        ]
      end
    end

    context 'when requesting `merged_at`' do
      let(:requested_fields) { [:merged_at] }
      let(:merge_request_ids) { [merge_request_a.id, merge_request_b.id, merge_request_c.id] }

      before do
        # make the MRs "merged"
        ::MergeRequest.where(id: merge_request_ids).update_all(state_id: MergeRequest.available_states[:merged])
        ::MergeRequest::Metrics.where(merge_request_id: merge_request_ids).update_all(merged_at: Time.now)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `closed_at`' do
      let(:requested_fields) { [:closed_at] }
      let(:merge_request_ids) { [merge_request_a.id, merge_request_b.id, merge_request_c.id] }

      before do
        # make the MRs "closed"
        ::MergeRequest.where(id: merge_request_ids).update_all(state_id: MergeRequest.available_states[:closed])
        ::MergeRequest::Metrics.where(merge_request_id: merge_request_ids).update_all(latest_closed_at: Time.now)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `user_notes_count`' do
      let(:requested_fields) { [:user_notes_count] }

      before do
        create_list(:note_on_merge_request, 2, noteable: merge_request_a, project: project)
        create(:note_on_merge_request, noteable: merge_request_c, project: project)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `user_discussions_count`' do
      let(:requested_fields) { [:user_discussions_count] }

      before do
        create_list(:note_on_merge_request, 2, noteable: merge_request_a, project: project)
        create(:note_on_merge_request, noteable: merge_request_c, project: project)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting reviewers' do
      let(:requested_fields) { ['reviewers { nodes { username } }'] }

      before do
        merge_request_a.reviewers << create(:user)
        merge_request_a.reviewers << create(:user)
        merge_request_c.reviewers << create(:user)
      end

      it 'returns the reviewers' do
        nodes = merge_request_a.reviewers.map { |r| { 'username' => r.username } }
        reviewers = { 'nodes' => match_array(nodes) }

        execute_query

        expect(results).to include a_hash_including('reviewers' => match(reviewers))
      end

      include_examples 'N+1 query check'
    end

    context 'when award emoji votes' do
      let(:requested_fields) { 'upvotes downvotes awardEmoji { nodes { name } }' }

      before do
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_UP, awardable: merge_request_a)
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_DOWN, awardable: merge_request_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting labels' do
      let(:requested_fields) { ['labels { nodes { id } }'] }

      before do
        project_labels = create_list(:label, 2, project: project)
        group_labels = create_list(:group_label, 2, group: group)

        merge_request_c.update!(labels: [project_labels, group_labels].flatten)
      end

      include_examples 'N+1 query check', skip_cached: false
    end

    context 'when requesting diffStats' do
      let(:requested_fields) { ['diffStats { path }'] }

      before do
        create_list(:merge_request_diff, 2, merge_request: merge_request_a)
        create_list(:merge_request_diff, 2, merge_request: merge_request_b)
        create_list(:merge_request_diff, 2, merge_request: merge_request_c)
      end

      include_examples 'N+1 query check', skip_cached: false

      context 'when each merge request diff has no head_commit_sha' do
        before do
          [merge_request_a, merge_request_b, merge_request_c].each do |mr|
            mr.merge_request_diffs.update!(head_commit_sha: nil)
          end
        end

        include_examples 'N+1 query check', skip_cached: false
      end
    end
  end

  describe 'performance' do
    let(:mr_fields) do
      <<~SELECT
      assignees { nodes { username } }
      reviewers { nodes { username } }
      headPipeline { status }
      timelogs { nodes { timeSpent } }
      SELECT
    end

    let(:query) do
      <<~GQL
        query($first: Int) {
          project(fullPath: "#{project.full_path}") {
            mergeRequests(first: $first) {
              nodes { iid #{mr_fields} }
            }
          }
        }
      GQL
    end

    before_all do
      project.add_developer(current_user)
      mrs = create_list(
        :merge_request,
        10,
        :closed,
        :with_head_pipeline,
        source_project: project,
        author: current_user
      )
      mrs.each do |mr|
        mr.assignees << create(:user)
        mr.assignees << current_user
        mr.reviewers << create(:user)
        mr.reviewers << current_user
        mr.timelogs << create(:merge_request_timelog, merge_request: mr)
      end
    end

    before do
      # Confounding factor: makes DB calls in EE
      allow(Gitlab::Database).to receive(:read_only?).and_return(false)
    end

    def query_context
      { current_user: current_user }
    end

    def run_query(number)
      # Ensure that we have a fresh request store and batch-context between runs
      vars = { first: number }
      result = run_with_clean_state(query, context: query_context, variables: vars)

      graphql_dig_at(result.to_h, :data, :project, :merge_requests, :nodes)
    end

    def user_collection
      { 'nodes' => be_present.and(all(match(a_hash_including('username' => be_present)))) }
    end

    it 'returns appropriate results' do
      mrs = run_query(2)

      expect(mrs.size).to eq(2)
      expect(mrs).to all(
        match(
          a_hash_including(
            'assignees' => user_collection,
            'reviewers' => user_collection,
            'headPipeline' => { 'status' => be_present },
            'timelogs' => { 'nodes' => be_one }
          )))
    end

    it 'can lookahead to eliminate N+1 queries' do
      baseline = ActiveRecord::QueryRecorder.new { run_query(1) }

      expect { run_query(10) }.not_to exceed_query_limit(baseline)
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:project, :mergeRequests] }

    def pagination_results_data(nodes)
      nodes
    end

    def pagination_query(params)
      graphql_query_for(:project, { full_path: project.full_path }, <<~QUERY)
        mergeRequests(#{params}) {
          #{page_info} nodes { id }
        }
      QUERY
    end

    context 'when sorting by merged_at DESC' do
      let(:sort_param) { :MERGED_AT_DESC }
      let(:all_records) do
        [
          merge_request_b,
          merge_request_d,
          merge_request_c,
          merge_request_e,
          merge_request_a
        ].map { |mr| a_graphql_entity_for(mr) }
      end

      before do
        five_days_ago = 5.days.ago

        merge_request_d.metrics.update!(merged_at: five_days_ago)

        # same merged_at, the second order column will decide (merge_request.id)
        merge_request_c.metrics.update!(merged_at: five_days_ago)

        merge_request_b.metrics.update!(merged_at: 1.day.ago)
      end

      it_behaves_like 'sorted paginated query' do
        let(:first_param) { 2 }
      end

      context 'when last parameter is given' do
        let(:params) { graphql_args(sort: sort_param, last: 2) }
        let(:page_info) { nil }

        it 'takes the last 2 records' do
          query = pagination_query(params)
          post_graphql(query, current_user: current_user)

          expect(results).to match(all_records.last(2))
        end
      end
    end

    context 'when sorting by closed_at DESC' do
      let(:sort_param) { :CLOSED_AT_DESC }
      let(:all_records) do
        [
          merge_request_b,
          merge_request_d,
          merge_request_c,
          merge_request_e,
          merge_request_a
        ].map { |mr| a_graphql_entity_for(mr) }
      end

      before do
        five_days_ago = 5.days.ago

        merge_request_d.metrics.update!(latest_closed_at: five_days_ago)

        # same merged_at, the second order column will decide (merge_request.id)
        merge_request_c.metrics.update!(latest_closed_at: five_days_ago)

        merge_request_b.metrics.update!(latest_closed_at: 1.day.ago)
      end

      it_behaves_like 'sorted paginated query' do
        let(:first_param) { 2 }
      end

      context 'when last parameter is given' do
        let(:params) { graphql_args(sort: sort_param, last: 2) }
        let(:page_info) { nil }

        it 'takes the last 2 records' do
          query = pagination_query(params)
          post_graphql(query, current_user: current_user)

          expect(results).to match(all_records.last(2))
        end
      end
    end
  end

  context 'when only the count is requested' do
    let_it_be(:merged_at) { Time.new(2020, 1, 3) }

    context 'when merged at filter is present' do
      let_it_be(:merge_request) do
        create(:merge_request, :unique_branches, source_project: project).tap do |mr|
          mr.metrics.update!(merged_at: merged_at, created_at: merged_at - 2.days)
        end
      end

      let(:query) do
        # Note: __typename meta field is always requested by the FE
        graphql_query_for(:project, { full_path: project.full_path }, <<~QUERY)
        mergeRequests(mergedAfter: "2020-01-01", mergedBefore: "2020-01-05", first: 0, sourceBranches: null, labels: null) {
          count
          __typename
        }
        QUERY
      end

      it 'does not query the merge requests table for the count' do
        query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

        queries = query_recorder.log
        expect(queries).not_to include(match(/SELECT COUNT\(\*\) FROM "merge_requests"/))
        expect(queries).to include(match(/SELECT COUNT\(\*\) FROM "merge_request_metrics"/))
      end

      context 'when total_time_to_merge and count is queried' do
        let_it_be(:merge_request_2) do
          create(:merge_request, :unique_branches, source_project: project).tap do |mr|
            mr.metrics.update!(merged_at: merged_at, created_at: merged_at - 1.day)
          end
        end

        let(:query) do
          # Adding a no-op `not` filter to mimic the same query as the frontend does
          graphql_query_for(:project, { full_path: project.full_path }, <<~QUERY)
          mergeRequests(mergedAfter: "2020-01-01", mergedBefore: "2020-01-05", first: 0, not: { labels: null }) {
            totalTimeToMerge
            count
          }
          QUERY
        end

        it 'uses the merge_request_metrics table for total_time_to_merge' do
          query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

          expect(query_recorder.log).to include(match(/SELECT.+SUM.+FROM "merge_request_metrics" WHERE/))
        end

        it 'returns the correct total time to merge' do
          post_graphql(query, current_user: current_user)

          sum = graphql_data_at(:project, :merge_requests, :total_time_to_merge)

          expect(sum).to eq(3.days.to_f)
        end
      end

      it 'returns the correct count' do
        post_graphql(query, current_user: current_user)

        count = graphql_data.dig('project', 'mergeRequests', 'count')
        expect(count).to eq(1)
      end
    end
  end
end
