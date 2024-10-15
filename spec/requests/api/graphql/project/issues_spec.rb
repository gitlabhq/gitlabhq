# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:another_user) { create(:user, reporter_of: group) }
  let_it_be(:milestone1) { create(:milestone, project: project, due_date: 10.days.from_now) }
  let_it_be(:milestone2) { create(:milestone, project: project, due_date: 20.days.from_now) }
  let_it_be(:milestone3) { create(:milestone, project: project, due_date: 30.days.from_now) }
  let_it_be(:milestone4) { create(:milestone, project: project, due_date: 40.days.from_now) }
  let_it_be(:priority1) { create(:label, project: project, priority: 1) }
  let_it_be(:priority2) { create(:label, project: project, priority: 5) }
  let_it_be(:priority3) { create(:label, project: project, priority: 10) }

  let_it_be(:issue_a) do
    create(
      :issue,
      project: project,
      discussion_locked: true,
      labels: [priority3],
      relative_position: 1000,
      milestone: milestone4
    )
  end

  let_it_be(:issue_b) do
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

  let_it_be(:subscription) { create(:subscription, subscribable: issue_a, user: current_user, subscribed: true) }
  let_it_be(:unsubscription) do
    create(:subscription, subscribable: issue_b, user: current_user, subscribed: false)
  end

  let_it_be(:issues, reload: true) { [issue_a, issue_b, issue_c, issue_d, issue_e] }

  let(:issue_nodes_path) { %w[project issues nodes] }
  let(:issue_filter_params) { {} }

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
    let(:voted_issues) { [issue_a] }
    let(:no_award_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:locked_discussion_issues) { [issue_a] }
    let(:unlocked_discussion_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:search_title_term) { 'matching issue' }
    let(:title_search_issue) { issue_b }
    let(:confidential_issues) { [issue_e] }
    let(:non_confidential_issues) { [issue_a, issue_b, issue_c, issue_d] }
    let(:public_non_confidential_issues) { non_confidential_issues }
    let(:subscribed_issues) { [issue_a] }
    let(:unsubscribed_issues) { [issue_b] }

    # sorting
    let(:data_path) { [:project, :issues] }
    let(:expected_priority_sorted_asc) { [issue_b, issue_c, issue_d, issue_a, issue_e] }
    let(:expected_priority_sorted_desc) { [issue_a, issue_d, issue_c, issue_b, issue_e] }
    let(:expected_due_date_sorted_desc) { [issue_d, issue_e, issue_c, issue_b, issue_a] }
    let(:expected_due_date_sorted_asc) { [issue_b, issue_c, issue_e, issue_d, issue_a] }
    let(:expected_relative_position_sorted_asc) { [issue_a, issue_b, issue_d, issue_c, issue_e] }
    let(:expected_label_priority_sorted_asc) { [issue_c, issue_d, issue_b, issue_a, issue_e] }
    let(:expected_label_priority_sorted_desc) { [issue_a, issue_d, issue_b, issue_c, issue_e] }
    let(:expected_milestone_sorted_asc) { [issue_b, issue_c, issue_d, issue_a, issue_e] }
    let(:expected_milestone_sorted_desc) { [issue_a, issue_d, issue_c, issue_b, issue_e] }

    # N+1 queries
    let(:same_project_issue1) { issue_a }
    let(:same_project_issue2) { issue_b }

    before_all do
      create(:award_emoji, :upvote, user: current_user, awardable: issue_a)
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

  def query(params = issue_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', params, fields)
    )
  end
end
