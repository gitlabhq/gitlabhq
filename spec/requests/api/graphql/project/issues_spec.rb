# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:another_user) { create(:user).tap { |u| group.add_reporter(u) } }
  let_it_be(:milestone1) { create(:milestone, project: project, due_date: 10.days.from_now) }
  let_it_be(:milestone2) { create(:milestone, project: project, due_date: 20.days.from_now) }
  let_it_be(:milestone3) { create(:milestone, project: project, due_date: 30.days.from_now) }
  let_it_be(:milestone4) { create(:milestone, project: project, due_date: 40.days.from_now) }
  let_it_be(:priority1) { create(:label, project: project, priority: 1) }
  let_it_be(:priority2) { create(:label, project: project, priority: 5) }
  let_it_be(:priority3) { create(:label, project: project, priority: 10) }

  let_it_be(:issue_a, reload: true) do
    create(
      :issue,
      project: project,
      discussion_locked: true,
      labels: [priority3],
      relative_position: 1000,
      milestone: milestone4
    )
  end

  let_it_be(:issue_b, reload: true) do
    create(
      :issue,
      :with_alert,
      project: project,
      title: 'title matching issue i',
      due_date: 3.days.ago,
      relative_position: 3000,
      labels: [priority2, priority3],
      milestone: milestone1
    )
  end

  let_it_be(:issue_c) do
    create(
      :issue,
      project: project,
      labels: [priority1],
      milestone: milestone2,
      due_date: 1.day.ago,
      relative_position: nil
    )
  end

  let_it_be(:issue_d) do
    create(:issue,
      project: project,
      labels: [priority2],
      due_date: 3.days.from_now,
      relative_position: 5000,
      milestone: milestone3
    )
  end

  let_it_be(:issue_e) do
    create(
      :issue,
      :confidential,
      project: project,
      due_date: 1.day.from_now,
      relative_position: nil
    )
  end

  let_it_be(:issues, reload: true) { [issue_a, issue_b, issue_c, issue_d, issue_e] }

  let(:issue_a_gid) { issue_a.to_global_id.to_s }
  let(:issue_b_gid) { issue_b.to_global_id.to_s }
  let(:issues_data) { graphql_data['project']['issues']['nodes'] }
  let(:issue_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('issues'.classify)}
    }
    QUERY
  end

  # All new specs should be added to the shared example if the change also
  # affects the `issues` query at the root level of the API.
  # Shared example also used in spec/requests/api/graphql/issues_spec.rb
  it_behaves_like 'graphql issue list request spec' do
    let_it_be(:external_user) { create(:user) }

    let(:public_projects) { [project] }

    before_all do
      group.add_developer(current_user)
    end

    # filters
    let(:expected_negated_assignee_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:expected_unioned_assignee_issues) { [issue_a, issue_b] }
    let(:voted_issues) { [issue_a] }
    let(:no_award_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:locked_discussion_issues) { [issue_a] }
    let(:unlocked_discussion_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:search_title_term) { 'matching issue' }
    let(:title_search_issue) { issue_b }
    let(:confidential_issues) { [issue_e] }
    let(:non_confidential_issues) { [issue_a, issue_b, issue_c, issue_d] }
    let(:public_non_confidential_issues) { non_confidential_issues }

    # sorting
    let(:data_path) { [:project, :issues] }
    let(:expected_severity_sorted_asc) { [issue_c, issue_a, issue_b, issue_e, issue_d] }
    let(:expected_priority_sorted_asc) { [issue_b, issue_c, issue_d, issue_a, issue_e] }
    let(:expected_priority_sorted_desc) { [issue_a, issue_d, issue_c, issue_b, issue_e] }
    let(:expected_due_date_sorted_desc) { [issue_d, issue_e, issue_c, issue_b, issue_a] }
    let(:expected_due_date_sorted_asc) { [issue_b, issue_c, issue_e, issue_d, issue_a] }
    let(:expected_relative_position_sorted_asc) { [issue_a, issue_b, issue_d, issue_c, issue_e] }
    let(:expected_label_priority_sorted_asc) { [issue_c, issue_d, issue_b, issue_a, issue_e] }
    let(:expected_label_priority_sorted_desc) { [issue_a, issue_d, issue_b, issue_c, issue_e] }
    let(:expected_milestone_sorted_asc) { [issue_b, issue_c, issue_d, issue_a, issue_e] }
    let(:expected_milestone_sorted_desc) { [issue_a, issue_d, issue_c, issue_b, issue_e] }

    before_all do
      issue_a.assignee_ids = current_user.id
      issue_b.assignee_ids = another_user.id

      create(:award_emoji, :upvote, user: current_user, awardable: issue_a)

      # severity sorting
      create(:issuable_severity, issue: issue_a, severity: :unknown)
      create(:issuable_severity, issue: issue_b, severity: :low)
      create(:issuable_severity, issue: issue_d, severity: :critical)
      create(:issuable_severity, issue: issue_e, severity: :high)
    end

    def pagination_query(params)
      graphql_query_for(
        :project,
        { full_path: project.full_path },
        query_graphql_field(:issues, params, "#{page_info} nodes { id }")
      )
    end

    def post_query(request_user = current_user)
      post_graphql(query, current_user: request_user)
    end
  end

  context 'when fetching alert management alert' do
    let(:fields) do
      <<~QUERY
        nodes {
          iid
          alertManagementAlert {
            title
          }
          alertManagementAlerts {
            nodes {
              title
            }
          }
        }
      QUERY
    end

    # Alerts need to have developer permission and above
    before do
      project.add_developer(current_user)
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      create(:alert_management_alert, :with_incident, project: project)

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
    end

    it 'returns the alert data' do
      post_graphql(query, current_user: current_user)

      alert_titles = issues_data.map { |issue| issue.dig('alertManagementAlert', 'title') }
      expected_titles = issues.map { |issue| issue.alert_management_alerts.first&.title }

      expect(alert_titles).to contain_exactly(*expected_titles)
    end

    it 'returns the alerts data' do
      post_graphql(query, current_user: current_user)

      alert_titles = issues_data.map { |issue| issue.dig('alertManagementAlerts', 'nodes') }
      expected_titles = issues.map do |issue|
        issue.alert_management_alerts.map { |alert| { 'title' => alert.title } }
      end

      expect(alert_titles).to contain_exactly(*expected_titles)
    end
  end

  context 'when fetching customer_relations_contacts' do
    let(:fields) do
      <<~QUERY
      nodes {
        id
        customerRelationsContacts {
          nodes {
            firstName
          }
        }
      }
      QUERY
    end

    def clean_state_query
      run_with_clean_state(query, context: { current_user: current_user })
    end

    it 'avoids N+1 queries' do
      create(:issue_customer_relations_contact, :for_issue, issue: issue_a)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { clean_state_query }

      create(:issue_customer_relations_contact, :for_issue, issue: issue_a)

      expect { clean_state_query }.not_to exceed_all_query_limit(control)
    end
  end

  context 'when fetching labels' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          labels {
            nodes {
              id
            }
          }
        }
      QUERY
    end

    before do
      project.add_developer(current_user)
      issues.each do |issue|
        # create a label for each issue we have to properly test N+1
        label = create(:label, project: project)
        issue.update!(labels: [label])
      end
    end

    def response_label_ids(response_data)
      response_data.map do |node|
        node['labels']['nodes'].map { |u| u['id'] }
      end.flatten
    end

    def labels_as_global_ids(issues)
      issues.map(&:labels).flatten.map(&:to_global_id).map(&:to_s)
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }
      expect(issues_data.count).to eq(5)
      expect(response_label_ids(issues_data)).to match_array(labels_as_global_ids(issues))

      new_issues = issues + [create(:issue, project: project, labels: [create(:label, project: project)])]

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
      # graphql_data is memoized (see spec/support/helpers/graphql_helpers.rb)
      # so we have to parse the body ourselves the second time
      issues_data = Gitlab::Json.parse(response.body)['data']['project']['issues']['nodes']
      expect(issues_data.count).to eq(6)
      expect(response_label_ids(issues_data)).to match_array(labels_as_global_ids(new_issues))
    end
  end

  context 'when fetching assignees' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          assignees {
            nodes {
              id
            }
          }
        }
      QUERY
    end

    before do
      project.add_developer(current_user)
      issues.each do |issue|
        # create an assignee for each issue we have to properly test N+1
        assignee = create(:user)
        issue.update!(assignees: [assignee])
      end
    end

    def response_assignee_ids(response_data)
      response_data.map do |node|
        node['assignees']['nodes'].map { |node| node['id'] }
      end.flatten
    end

    def assignees_as_global_ids(issues)
      issues.map(&:assignees).flatten.map(&:to_global_id).map(&:to_s)
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }
      expect(issues_data.count).to eq(5)
      expect(response_assignee_ids(issues_data)).to match_array(assignees_as_global_ids(issues))

      new_issues = issues + [create(:issue, project: project, assignees: [create(:user)])]

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
      # graphql_data is memoized (see spec/support/helpers/graphql_helpers.rb)
      # so we have to parse the body ourselves the second time
      issues_data = Gitlab::Json.parse(response.body)['data']['project']['issues']['nodes']
      expect(issues_data.count).to eq(6)
      expect(response_assignee_ids(issues_data)).to match_array(assignees_as_global_ids(new_issues))
    end
  end

  describe 'N+1 query checks' do
    let(:extra_iid_for_second_query) { issue_b.iid.to_s }
    let(:search_params) { { iids: [issue_a.iid.to_s] } }

    def execute_query
      query = graphql_query_for(
        :project,
        { full_path: project.full_path },
        query_graphql_field(
          :issues, search_params,
          query_graphql_field(:nodes, nil, requested_fields)
        )
      )
      post_graphql(query, current_user: current_user)
    end

    context 'when requesting `user_notes_count`' do
      let(:requested_fields) { [:user_notes_count] }

      before do
        create_list(:note_on_issue, 2, noteable: issue_a, project: project)
        create(:note_on_issue, noteable: issue_b, project: project)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `user_discussions_count`' do
      let(:requested_fields) { [:user_discussions_count] }

      before do
        create_list(:note_on_issue, 2, noteable: issue_a, project: project)
        create(:note_on_issue, noteable: issue_b, project: project)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `merge_requests_count`' do
      let(:requested_fields) { [:merge_requests_count] }

      before do
        create_list(:merge_requests_closing_issues, 2, issue: issue_a)
        create_list(:merge_requests_closing_issues, 3, issue: issue_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `timelogs`' do
      let(:requested_fields) { 'timelogs { nodes { timeSpent } }' }

      before do
        create_list(:issue_timelog, 2, issue: issue_a)
        create(:issue_timelog, issue: issue_b)
      end

      include_examples 'N+1 query check'
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'when requesting `closed_as_duplicate_of`' do
      let(:requested_fields) { 'closedAsDuplicateOf { id }' }
      let(:issue_a_dup) { create(:issue, project: project) }
      let(:issue_b_dup) { create(:issue, project: project) }

      before do
        issue_a.update!(duplicated_to_id: issue_a_dup)
        issue_b.update!(duplicated_to_id: issue_a_dup)
      end

      include_examples 'N+1 query check'
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'when award emoji votes' do
      let(:requested_fields) { [:upvotes, :downvotes] }

      before do
        create_list(:award_emoji, 2, name: 'thumbsup', awardable: issue_a)
        create_list(:award_emoji, 2, name: 'thumbsdown', awardable: issue_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting participants' do
      let_it_be(:issue_c) { create(:issue, project: project) }

      let(:search_params) { { iids: [issue_a.iid.to_s, issue_c.iid.to_s] } }
      let(:requested_fields) { 'participants { nodes { name } }' }

      before do
        create(:award_emoji, :upvote, awardable: issue_a)
        create(:award_emoji, :upvote, awardable: issue_b)
        create(:award_emoji, :upvote, awardable: issue_c)

        note_with_emoji_a = create(:note_on_issue, noteable: issue_a, project: project)
        note_with_emoji_b = create(:note_on_issue, noteable: issue_b, project: project)
        note_with_emoji_c = create(:note_on_issue, noteable: issue_c, project: project)

        create(:award_emoji, :upvote, awardable: note_with_emoji_a)
        create(:award_emoji, :upvote, awardable: note_with_emoji_b)
        create(:award_emoji, :upvote, awardable: note_with_emoji_c)
      end

      # Executes 3 extra queries to fetch participant_attrs
      include_examples 'N+1 query check', threshold: 3
    end

    context 'when requesting labels' do
      let(:requested_fields) { ['labels { nodes { id } }'] }

      before do
        project_labels = create_list(:label, 2, project: project)
        group_labels = create_list(:group_label, 2, group: group)

        issue_a.update!(labels: [project_labels.first, group_labels.first].flatten)
        issue_b.update!(labels: [project_labels, group_labels].flatten)
      end

      include_examples 'N+1 query check', skip_cached: false
    end
  end

  def issue_ids
    graphql_dig_at(issues_data, :id)
  end

  def query(params = issue_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', params, fields)
    )
  end
end
