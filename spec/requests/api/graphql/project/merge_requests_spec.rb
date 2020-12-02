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
      query_graphql_field(:merge_requests, search_params, [
        query_graphql_field(:nodes, nil, fields)
      ])
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

    context 'selecting any single scalar field' do
      where(:field) do
        scalar_fields_of('MergeRequest').map { |name| [name] }
      end

      with_them do
        it_behaves_like 'a working graphql query' do
          let(:query) do
            query_merge_requests([:iid, field].uniq)
          end

          before do
            post_graphql(query, current_user: current_user)
          end

          it 'selects the correct MR' do
            expect(results).to contain_exactly(a_hash_including('iid' => fresh_mr.iid.to_s))
          end
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
        it_behaves_like 'a working graphql query' do
          let(:query) do
            fld = is_connection ? query_graphql_field(:nodes, nil, [subfield]) : subfield
            query_merge_requests([:iid, query_graphql_field(field, nil, [fld])])
          end

          before do
            post_graphql(query, current_user: current_user)
          end

          it 'selects the correct MR' do
            expect(results).to contain_exactly(a_hash_including('iid' => fresh_mr.iid.to_s))
          end
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
end
