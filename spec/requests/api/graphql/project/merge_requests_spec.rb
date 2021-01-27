# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request listings nested in a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:merge_request_a) { create(:labeled_merge_request, :unique_branches, source_project: project, labels: [label]) }
  let_it_be(:merge_request_b) { create(:merge_request, :closed, :unique_branches, source_project: project) }
  let_it_be(:merge_request_c) { create(:labeled_merge_request, :closed, :unique_branches, source_project: project, labels: [label]) }
  let_it_be(:merge_request_d) { create(:merge_request, :locked, :unique_branches, source_project: project) }
  let_it_be(:merge_request_e) { create(:merge_request, :unique_branches, source_project: project) }

  let(:results) { graphql_data.dig('project', 'mergeRequests', 'nodes') }

  let(:search_params) { nil }

  def query_merge_requests(fields)
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:merge_requests, fields, args: search_params)
    )
  end

  let(:query) do
    query_merge_requests(all_graphql_fields_for('MergeRequest', max_depth: 1))
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  # The following tests are needed to guarantee that we have correctly annotated
  # all the gitaly calls.  Selecting combinations of fields may mask this due to
  # memoization.
  context 'requesting a single field' do
    let_it_be(:fresh_mr) { create(:merge_request, :unique_branches, source_project: project) }
    let(:search_params) { { iids: [fresh_mr.iid.to_s] } }

    before do
      project.repository.expire_branches_cache
    end

    let(:graphql_data) do
      GitlabSchema.execute(query, context: { current_user: current_user }).to_h['data']
    end

    context 'selecting any single scalar field' do
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

    context 'selecting any single nested field' do
      where(:field, :subfield, :is_connection) do
        nested_fields_of('MergeRequest').flat_map do |name, field|
          type = field_type(field)
          is_connection = type.name.ends_with?('Connection')
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

  shared_examples 'searching with parameters' do
    let(:expected) do
      mrs.map { |mr| a_hash_including('iid' => mr.iid.to_s, 'title' => mr.title) }
    end

    it 'finds the right mrs' do
      post_graphql(query, current_user: current_user)

      expect(results).to match_array(expected)
    end
  end

  context 'there are no search params' do
    let(:search_params) { nil }
    let(:mrs) { [merge_request_a, merge_request_b, merge_request_c, merge_request_d, merge_request_e] }

    it_behaves_like 'searching with parameters'
  end

  context 'the search params do not match anything' do
    let(:search_params) { { iids: %w(foo bar baz) } }
    let(:mrs) { [] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by iids' do
    let(:search_params) { { iids: mrs.map(&:iid).map(&:to_s) } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by state' do
    let(:search_params) { { state: :closed } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by source_branch' do
    let(:search_params) { { source_branches: mrs.map(&:source_branch) } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by target_branch' do
    let(:search_params) { { target_branches: mrs.map(&:target_branch) } }
    let(:mrs) { [merge_request_a, merge_request_d] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by label' do
    let(:search_params) { { labels: [label.title] } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by combination' do
    let(:search_params) { { state: :closed, labels: [label.title] } }
    let(:mrs) { [merge_request_c] }

    it_behaves_like 'searching with parameters'
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
      let(:requested_fields) { [:commit_count] }

      it 'exposes `commit_count`' do
        merge_request_a.metrics.update!(commits_count: 5)

        execute_query

        expect(results).to include(a_hash_including('commitCount' => 5))
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `merged_at`' do
      let(:requested_fields) { [:merged_at] }

      before do
        # make the MRs "merged"
        [merge_request_a, merge_request_b, merge_request_c].each do |mr|
          mr.update_column(:state_id, MergeRequest.available_states[:merged])
          mr.metrics.update_column(:merged_at, Time.now)
        end
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
        execute_query

        expect(results).to include a_hash_including('reviewers' => {
          'nodes' => match_array(merge_request_a.reviewers.map do |r|
            a_hash_including('username' => r.username)
          end)
        })
      end

      context 'the feature flag is disabled' do
        before do
          stub_feature_flags(merge_request_reviewers: false)
        end

        it 'does not return reviewers' do
          execute_query

          expect(results).to all(match a_hash_including('reviewers' => be_nil))
        end
      end

      include_examples 'N+1 query check'
    end
  end

  describe 'performance' do
    let(:mr_fields) do
      <<~SELECT
      assignees { nodes { username } }
      reviewers { nodes { username } }
      participants { nodes { username } }
      headPipeline { status }
      SELECT
    end

    let(:query) do
      <<~GQL
        query($first: Int) {
          project(fullPath: "#{project.full_path}") {
            mergeRequests(first: $first) {
              nodes { #{mr_fields} }
            }
          }
        }
      GQL
    end

    before_all do
      project.add_developer(current_user)
      mrs = create_list(:merge_request, 10, :closed, :with_head_pipeline,
                        source_project: project,
                        author: current_user)
      mrs.each do |mr|
        mr.assignees << create(:user)
        mr.assignees << current_user
        mr.reviewers << create(:user)
        mr.reviewers << current_user
      end
    end

    before do
      # Confounding factor: makes DB calls in EE
      allow(Gitlab::Database).to receive(:read_only?).and_return(false)
    end

    def run_query(number)
      # Ensure that we have a fresh request store and batch-context between runs
      result = run_with_clean_state(query,
        context: { current_user: current_user },
        variables: { first: number }
      )

      graphql_dig_at(result.to_h, :data, :project, :merge_requests, :nodes)
    end

    def user_collection
      { 'nodes' => all(match(a_hash_including('username' => be_present))) }
    end

    it 'returns appropriate results' do
      mrs = run_query(2)

      expect(mrs.size).to eq(2)
      expect(mrs).to all(
        match(
          a_hash_including(
            'assignees' => user_collection,
            'reviewers' => user_collection,
            'participants' => user_collection,
            'headPipeline' => { 'status' => be_present }
          )))
    end

    it 'can lookahead to eliminate N+1 queries' do
      baseline = ActiveRecord::QueryRecorder.new { run_query(1) }

      expect { run_query(10) }.not_to exceed_query_limit(baseline)
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:project, :mergeRequests] }

    def pagination_query(params)
      graphql_query_for(:project, { full_path: project.full_path },
        <<~QUERY
        mergeRequests(#{params}) {
          #{page_info} nodes { id }
        }
        QUERY
      )
    end

    context 'when sorting by merged_at DESC' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :MERGED_AT_DESC }
        let(:first_param) { 2 }

        let(:expected_results) do
          [
            merge_request_b,
            merge_request_d,
            merge_request_c,
            merge_request_e,
            merge_request_a
          ].map { |mr| global_id_of(mr) }
        end

        before do
          five_days_ago = 5.days.ago

          merge_request_d.metrics.update!(merged_at: five_days_ago)

          # same merged_at, the second order column will decide (merge_request.id)
          merge_request_c.metrics.update!(merged_at: five_days_ago)

          merge_request_b.metrics.update!(merged_at: 1.day.ago)
        end
      end
    end
  end

  context 'when only the count is requested' do
    context 'when merged at filter is present' do
      let_it_be(:merge_request) do
        create(:merge_request, :unique_branches, source_project: project).tap do |mr|
          mr.metrics.update!(merged_at: Time.new(2020, 1, 3))
        end
      end

      let(:query) do
        graphql_query_for(:project, { full_path: project.full_path },
        <<~QUERY
        mergeRequests(mergedAfter: "2020-01-01", mergedBefore: "2020-01-05", first: 0) {
          count
        }
        QUERY
        )
      end

      shared_examples 'count examples' do
        it 'returns the correct count' do
          post_graphql(query, current_user: current_user)

          count = graphql_data.dig('project', 'mergeRequests', 'count')
          expect(count).to eq(1)
        end
      end

      context 'when "optimized_merge_request_count_with_merged_at_filter" feature flag is enabled' do
        before do
          stub_feature_flags(optimized_merge_request_count_with_merged_at_filter: true)
        end

        it 'does not query the merge requests table for the count' do
          query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

          queries = query_recorder.data.each_value.first[:occurrences]
          expect(queries).not_to include(match(/SELECT COUNT\(\*\) FROM "merge_requests"/))
          expect(queries).to include(match(/SELECT COUNT\(\*\) FROM "merge_request_metrics"/))
        end

        context 'when total_time_to_merge and count is queried' do
          let(:query) do
            graphql_query_for(:project, { full_path: project.full_path },
            <<~QUERY
            mergeRequests(mergedAfter: "2020-01-01", mergedBefore: "2020-01-05", first: 0) {
              totalTimeToMerge
              count
            }
            QUERY
            )
          end

          it 'does not query the merge requests table for the total_time_to_merge' do
            query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

            queries = query_recorder.data.each_value.first[:occurrences]
            expect(queries).to include(match(/SELECT.+SUM.+FROM "merge_request_metrics" WHERE/))
          end
        end

        it_behaves_like 'count examples'

        context 'when "optimized_merge_request_count_with_merged_at_filter" feature flag is disabled' do
          before do
            stub_feature_flags(optimized_merge_request_count_with_merged_at_filter: false)
          end

          it 'queries the merge requests table for the count' do
            query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

            queries = query_recorder.data.each_value.first[:occurrences]
            expect(queries).to include(match(/SELECT COUNT\(\*\) FROM "merge_requests"/))
            expect(queries).not_to include(match(/SELECT COUNT\(\*\) FROM "merge_request_metrics"/))
          end

          it_behaves_like 'count examples'
        end
      end
    end
  end
end
