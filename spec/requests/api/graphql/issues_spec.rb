# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'getting an issue list at root level', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:current_user) { developer }
  let_it_be(:group1) { create(:group, developers: developer) }
  let_it_be(:group2) { create(:group, developers: developer, reporters: reporter) }
  let_it_be_with_reload(:project_a) { create(:project, :public, group: group1) }
  let_it_be(:project_b) { create(:project, :private, group: group1) }
  let_it_be_with_reload(:project_c) { create(:project, :public, group: group2) }
  let_it_be(:project_d) { create(:project, :private, group: group2) }
  let_it_be(:archived_project) { create(:project, :archived, group: group2) }
  let_it_be(:milestone1) { create(:milestone, project: project_c, due_date: 10.days.from_now) }
  let_it_be(:milestone2) { create(:milestone, project: project_d, due_date: 20.days.from_now) }
  let_it_be(:milestone3) { create(:milestone, project: project_d, due_date: 30.days.from_now) }
  let_it_be(:milestone4) { create(:milestone, project: project_a, due_date: 40.days.from_now) }
  let_it_be_with_reload(:priority1) { create(:label, project: project_c, priority: 1) }
  let_it_be_with_reload(:priority2) { create(:label, project: project_d, priority: 5) }
  let_it_be_with_reload(:priority3) { create(:label, project: project_a, priority: 10) }
  let_it_be_with_reload(:priority4) { create(:label, project: project_d, priority: 15) }

  let_it_be(:issue_a, freeze: false) do
    create(
      :issue,
      project: project_a,
      labels: [priority3],
      due_date: 1.day.ago,
      milestone: milestone4,
      relative_position: 1000
    )
  end

  let_it_be(:issue_b, freeze: false) do
    create(
      :issue,
      :with_alert,
      project: project_b,
      discussion_locked: true,
      due_date: 1.day.from_now,
      relative_position: 3000
    )
  end

  let_it_be(:issue_c) do
    create(
      :issue,
      :confidential,
      project: project_c,
      title: 'title matching issue plus',
      labels: [priority1],
      milestone: milestone1,
      due_date: 3.days.from_now,
      relative_position: nil
    )
  end

  let_it_be(:issue_d, freeze: false) do
    create(
      :issue,
      :with_alert,
      project: project_d,
      discussion_locked: true,
      labels: [priority2],
      milestone: milestone3,
      relative_position: 5000
    )
  end

  let_it_be(:issue_e, freeze: false) do
    create(
      :issue,
      :confidential,
      project: project_d,
      milestone: milestone2,
      due_date: 3.days.ago,
      relative_position: nil,
      labels: [priority2, priority4]
    )
  end

  let_it_be(:archived_issue) { create(:issue, project: archived_project) }
  let_it_be_with_reload(:issues) { [issue_a, issue_b, issue_c, issue_d, issue_e] }
  # we need to always provide at least one filter to the query so it doesn't fail
  let_it_be(:base_params) { { iids: issues.map { |issue| issue.iid.to_s } } }

  let_it_be(:subscription) { create(:subscription, subscribable: issue_a, user: current_user, subscribed: true) }
  let_it_be(:unsubscription) do
    create(:subscription, subscribable: issue_b, user: current_user, subscribed: false)
  end

  let(:issue_filter_params) { {} }
  let(:all_query_params) { base_params.merge(**issue_filter_params) }
  let(:fields) do
    <<~QUERY
      nodes { id }
    QUERY
  end

  shared_examples 'query that requires at least one filter' do
    it 'requires at least one filter to be provided to the query' do
      post_graphql(query, current_user: developer)

      expect(graphql_errors).to contain_exactly(
        hash_including('message' => _('You must provide at least one filter argument for this query'))
      )
    end
  end

  describe 'includeArchived filter' do
    let(:base_params) { { iids: [archived_issue.iid.to_s] } }

    it 'excludes issues from archived projects' do
      post_query

      issue_ids = graphql_dig_at(graphql_data_at('issues', 'nodes'), :id)

      expect(issue_ids).not_to include(archived_issue.to_gid.to_s)
    end

    context 'when includeArchived is true' do
      let(:issue_filter_params) { { include_archived: true } }

      it 'includes issues from archived projects' do
        post_query

        issue_ids = graphql_dig_at(graphql_data_at('issues', 'nodes'), :id)

        expect(issue_ids).to include(archived_issue.to_gid.to_s)
      end
    end
  end

  it 'excludes issues from archived projects' do
    post_query

    issue_ids = graphql_dig_at(graphql_data_at('issues', 'nodes'), :id)

    expect(issue_ids).not_to include(archived_issue.to_gid.to_s)
  end

  context 'when no filters are provided' do
    let(:all_query_params) { {} }

    it_behaves_like 'query that requires at least one filter'
  end

  context 'when only non filter arguments are provided' do
    let(:all_query_params) { { sort: :SEVERITY_ASC } }

    it_behaves_like 'query that requires at least one filter'
  end

  context 'when the only filter provided is a boolean set to false' do
    let(:all_query_params) { { confidential: false } }

    it 'accepts the filter and applies it' do
      post_query

      expect_graphql_errors_to_be_empty

      issue_ids = graphql_dig_at(graphql_data_at('issues', 'nodes'), :id)

      expect(issue_ids).to include(issue_a.to_gid.to_s)
      expect(issue_ids).not_to include(issue_c.to_gid.to_s, issue_e.to_gid.to_s)
    end
  end

  # All new specs should be added to the shared example if the change also
  # affects the `issues` query at the root level of the API.
  # Shared example also used in spec/requests/api/graphql/project/issues_spec.rb
  it_behaves_like 'graphql issue list request spec' do
    let_it_be(:external_user) { create(:user) }
    let_it_be(:another_user) { reporter }
    let_it_be(:project) { project_a } # Used for Service Desk issues creation in shared example

    let(:public_projects) { [project_a, project_c] }

    let(:issue_nodes_path) { %w[issues nodes] }

    # filters
    let(:expected_negated_assignee_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:voted_issues) { [issue_a, issue_c] }
    let(:no_award_issues) { [issue_b, issue_d, issue_e] }
    let(:locked_discussion_issues) { [issue_b, issue_d] }
    let(:unlocked_discussion_issues) { [issue_a, issue_c, issue_e] }
    let(:search_title_term) { 'matching issue' }
    let(:title_search_issue) { issue_c }
    let(:confidential_issues) { [issue_c, issue_e] }
    let(:non_confidential_issues) { [issue_a, issue_b, issue_d] }
    let(:public_non_confidential_issues) { [issue_a] }
    let(:subscribed_issues) { [issue_a] }
    let(:unsubscribed_issues) { [issue_b] }

    # sorting
    let(:data_path) { [:issues] }
    let(:expected_priority_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_priority_sorted_desc) { [issue_a, issue_d, issue_e, issue_c, issue_b] }
    let(:expected_due_date_sorted_desc) { [issue_c, issue_b, issue_a, issue_e, issue_d] }
    let(:expected_due_date_sorted_asc) { [issue_e, issue_a, issue_b, issue_c, issue_d] }
    let(:expected_relative_position_sorted_asc) { [issue_a, issue_b, issue_d, issue_c, issue_e] }
    let(:expected_label_priority_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_label_priority_sorted_desc) { [issue_a, issue_e, issue_d, issue_c, issue_b] }
    let(:expected_milestone_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_milestone_sorted_desc) { [issue_a, issue_d, issue_e, issue_c, issue_b] }

    # N+1 queries
    let(:same_project_issue1) { issue_d }
    let(:same_project_issue2) { issue_e }

    before_all do
      create(:award_emoji, :upvote, user: developer, awardable: issue_a)
      create(:award_emoji, :upvote, user: developer, awardable: issue_c)
    end

    def pagination_query(params)
      graphql_query_for(
        :issues,
        base_params.merge(**params.to_h),
        "#{page_info} nodes { id }"
      )
    end
  end

  context 'when fetching issues from multiple projects' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          reference
        }
      QUERY
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      post_query # warm-up

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_query }
      expect_graphql_errors_to_be_empty

      new_private_project = create(:project, :private, developers: current_user)
      create(:issue, project: new_private_project)

      private_group = create(:group, :private, developers: current_user)
      private_project = create(:project, :private, group: private_group)
      create(:issue, project: private_project)

      # Threshold increased from 1 to 4: the test adds 2 projects in 2 new root namespaces,
      # each requiring a one-time work_item_custom_types lookup for the configurable types
      # cache (keyed per root ancestor in SafeRequestStore). This is O(new namespaces),
      # not O(issues).
      expect { post_query }.not_to exceed_all_query_limit(control).with_threshold(4)
      expect_graphql_errors_to_be_empty
    end
  end

  context 'when fetching issue dates' do
    let_it_be(:dated_issue) do
      issue = create(:issue, project: project_a, author: developer)
      Issues::UpdateService.new(
        container: project_a,
        current_user: developer,
        params: {
          start_date: Date.new(2026, 9, 20),
          due_date: Date.new(2026, 9, 30)
        }
      ).execute(issue)

      issue.reload
    end

    let(:date_fields) { 'nodes { id startDate dueDate }' }
    let(:dated_issue_query) do
      graphql_query_for(
        :issues,
        { iids: [dated_issue.iid.to_s], author_username: developer.username },
        date_fields
      )
    end

    it 'returns persisted start and due dates' do
      expect(dated_issue.reload).to have_attributes(
        start_date: Date.new(2026, 9, 20),
        due_date: Date.new(2026, 9, 30)
      )
      expect(dated_issue.dates_source).to have_attributes(
        start_date: Date.new(2026, 9, 20),
        due_date: Date.new(2026, 9, 30)
      )

      result = run_with_clean_state(dated_issue_query, context: { current_user: current_user }).as_json

      expect(result['errors']).to be_nil
      expect(result.dig('data', 'issues', 'nodes')).to contain_exactly(
        include(
          'id' => dated_issue.to_gid.to_s,
          'startDate' => '2026-09-20',
          'dueDate' => '2026-09-30'
        )
      )
    end

    it 'does not cause N+1 queries' do
      control_user = create(:user)
      scale_user = create(:user)
      control_project = create(:project, :public)
      scale_project = create(:project, :public)
      control_issue = create(:issue, project: control_project, author: control_user, start_date: Date.new(2026, 9, 20))
      scale_issues = create_list(
        :issue, 2, project: scale_project, author: scale_user, start_date: Date.new(2026, 9, 20)
      )

      query_for = ->(user) do
        graphql_query_for(:issues, { author_username: user.username }, 'nodes { id startDate }')
      end

      control_result = nil
      control = ActiveRecord::QueryRecorder.new do
        control_result = run_with_clean_state(query_for.call(control_user), context: { current_user: control_user })
      end

      scale_result = nil
      expect do
        scale_result = run_with_clean_state(query_for.call(scale_user), context: { current_user: scale_user })
      end.not_to exceed_query_limit(control)

      expect(control_result['errors']).to be_nil
      expect(control_result.dig('data', 'issues', 'nodes')).to contain_exactly(
        include('id' => control_issue.to_gid.to_s, 'startDate' => '2026-09-20')
      )
      expect(scale_result['errors']).to be_nil
      expect(scale_result.dig('data', 'issues', 'nodes')).to match_array(
        scale_issues.map { |issue| include('id' => issue.to_gid.to_s, 'startDate' => '2026-09-20') }
      )
    end
  end

  context 'with rate limiting' do
    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit, graphql: true do
      let_it_be(:current_user) { developer }

      let(:error_message) do
        'This endpoint has been requested with the search argument too many times. Try again later.'
      end

      def request
        post_graphql(query({ search: 'test' }), current_user: developer)
      end

      def request_with_second_scope
        post_graphql(query({ search: 'test' }), current_user: reporter)
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit_unauthenticated, graphql: true do
      let_it_be(:current_user) { nil }

      let(:error_message) do
        'This endpoint has been requested with the search argument too many times. Try again later.'
      end

      def request
        post_graphql(query({ search: 'test' }))
      end

      def request_with_second_scope
        post_graphql(query({ search: 'different_test' }), headers: { 'REMOTE_ADDR' => '1.2.3.4' })
      end
    end
  end

  def execute_query
    post_query
  end

  def post_query(request_user = current_user)
    post_graphql(query, current_user: request_user)
  end

  def query(params = all_query_params)
    graphql_query_for(
      :issues,
      params,
      fields
    )
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
