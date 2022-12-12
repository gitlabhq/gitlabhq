# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list at root level', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:group1) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:group2) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:project_a) { create(:project, :repository, :public, group: group1) }
  let_it_be(:project_b) { create(:project, :repository, :private, group: group1) }
  let_it_be(:project_c) { create(:project, :repository, :public, group: group2) }
  let_it_be(:project_d) { create(:project, :repository, :private, group: group2) }
  let_it_be(:milestone1) { create(:milestone, project: project_c, due_date: 10.days.from_now) }
  let_it_be(:milestone2) { create(:milestone, project: project_d, due_date: 20.days.from_now) }
  let_it_be(:milestone3) { create(:milestone, project: project_d, due_date: 30.days.from_now) }
  let_it_be(:milestone4) { create(:milestone, project: project_a, due_date: 40.days.from_now) }
  let_it_be(:priority1) { create(:label, project: project_c, priority: 1) }
  let_it_be(:priority2) { create(:label, project: project_d, priority: 5) }
  let_it_be(:priority3) { create(:label, project: project_a, priority: 10) }
  let_it_be(:priority4) { create(:label, project: project_d, priority: 15) }

  let_it_be(:issue_a) do
    create(
      :issue,
      project: project_a,
      labels: [priority3],
      due_date: 1.day.ago,
      milestone: milestone4,
      relative_position: 1000
    )
  end

  let_it_be(:issue_b) do
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

  let_it_be(:issue_d) do
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

  let_it_be(:issue_e) do
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

  let_it_be(:issues, reload: true) { [issue_a, issue_b, issue_c, issue_d, issue_e] }

  let(:issue_filter_params) { {} }
  let(:current_user) { developer }
  let(:fields) do
    <<~QUERY
      nodes { id }
    QUERY
  end

  before_all do
    group2.add_reporter(reporter)
  end

  context 'when the root_level_issues_query feature flag is disabled' do
    before do
      stub_feature_flags(root_level_issues_query: false)
    end

    it 'the field returns null' do
      post_graphql(query, current_user: developer)

      expect(graphql_data).to eq('issues' => nil)
    end
  end

  # All new specs should be added to the shared example if the change also
  # affects the `issues` query at the root level of the API.
  # Shared example also used in spec/requests/api/graphql/project/issues_spec.rb
  it_behaves_like 'graphql issue list request spec' do
    let_it_be(:external_user) { create(:user) }

    let(:public_projects) { [project_a, project_c] }

    let(:another_user) { reporter }
    let(:issue_nodes_path) { %w[issues nodes] }

    # filters
    let(:expected_negated_assignee_issues) { [issue_b, issue_c, issue_d, issue_e] }
    let(:expected_unioned_assignee_issues) { [issue_a, issue_c] }
    let(:voted_issues) { [issue_a, issue_c] }
    let(:no_award_issues) { [issue_b, issue_d, issue_e] }
    let(:locked_discussion_issues) { [issue_b, issue_d] }
    let(:unlocked_discussion_issues) { [issue_a, issue_c, issue_e] }
    let(:search_title_term) { 'matching issue' }
    let(:title_search_issue) { issue_c }
    let(:confidential_issues) { [issue_c, issue_e] }
    let(:non_confidential_issues) { [issue_a, issue_b, issue_d] }
    let(:public_non_confidential_issues) { [issue_a] }

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
      issue_a.assignee_ids = developer.id
      issue_c.assignee_ids = reporter.id

      create(:award_emoji, :upvote, user: developer, awardable: issue_a)
      create(:award_emoji, :upvote, user: developer, awardable: issue_c)
    end

    def pagination_query(params)
      graphql_query_for(
        :issues,
        params,
        "#{page_info} nodes { id }"
      )
    end
  end

  context 'when fetching issues from multiple projects' do
    it 'avoids N+1 queries' do
      post_query # warm-up

      control = ActiveRecord::QueryRecorder.new { post_query }

      new_private_project = create(:project, :private).tap { |project| project.add_developer(current_user) }
      create(:issue, project: new_private_project)

      expect { post_query }.not_to exceed_query_limit(control)
    end
  end

  def execute_query
    post_query
  end

  def post_query(request_user = current_user)
    post_graphql(query, current_user: request_user)
  end

  def query(params = issue_filter_params)
    graphql_query_for(
      :issues,
      params,
      fields
    )
  end
end
