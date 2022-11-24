# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list at root level' do
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

  let(:issues) { [issue_a, issue_b, issue_c, issue_d, issue_e] }
  let(:issue_filter_params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('issues'.classify)}
      }
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

  it_behaves_like 'graphql issue list request spec' do
    let_it_be(:external_user) { create(:user) }

    let(:public_projects) { [project_a, project_c] }

    let(:current_user) { developer }
    let(:another_user) { reporter }
    let(:issues_data) { graphql_data['issues']['nodes'] }
    let(:issue_ids) { graphql_dig_at(issues_data, :id) }

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
    let(:expected_severity_sorted_asc) { [issue_c, issue_a, issue_b, issue_e, issue_d] }
    let(:expected_priority_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_priority_sorted_desc) { [issue_a, issue_d, issue_e, issue_c, issue_b] }
    let(:expected_due_date_sorted_desc) { [issue_c, issue_b, issue_a, issue_e, issue_d] }
    let(:expected_due_date_sorted_asc) { [issue_e, issue_a, issue_b, issue_c, issue_d] }
    let(:expected_relative_position_sorted_asc) { [issue_a, issue_b, issue_d, issue_c, issue_e] }
    let(:expected_label_priority_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_label_priority_sorted_desc) { [issue_a, issue_e, issue_d, issue_c, issue_b] }
    let(:expected_milestone_sorted_asc) { [issue_c, issue_e, issue_d, issue_a, issue_b] }
    let(:expected_milestone_sorted_desc) { [issue_a, issue_d, issue_e, issue_c, issue_b] }

    before_all do
      issue_a.assignee_ids = developer.id
      issue_c.assignee_ids = reporter.id

      create(:award_emoji, :upvote, user: developer, awardable: issue_a)
      create(:award_emoji, :upvote, user: developer, awardable: issue_c)

      # severity sorting
      create(:issuable_severity, issue: issue_a, severity: :unknown)
      create(:issuable_severity, issue: issue_b, severity: :low)
      create(:issuable_severity, issue: issue_d, severity: :critical)
      create(:issuable_severity, issue: issue_e, severity: :high)
    end

    def pagination_query(params)
      graphql_query_for(
        :issues,
        params,
        "#{page_info} nodes { id }"
      )
    end

    def post_query(request_user = current_user)
      post_graphql(query, current_user: request_user)
    end
  end

  def query(params = issue_filter_params)
    graphql_query_for(
      :issues,
      params,
      fields
    )
  end
end
