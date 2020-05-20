# frozen_string_literal: true

require 'spec_helper'

describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:current_user) { create(:user) }
  let(:issues_data) { graphql_data['project']['issues']['edges'] }
  let!(:issues) do
    [create(:issue, project: project, discussion_locked: true),
     create(:issue, project: project)]
  end
  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('issues'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', {}, fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'includes a web_url' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['webUrl']).to be_present
  end

  it 'includes discussion locked' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['discussionLocked']).to eq(false)
    expect(issues_data[1]['node']['discussionLocked']).to eq(true)
  end

  context 'when limiting the number of results' do
    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        "issues(first: 1) { #{fields} }"
      )
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'is expected to check permissions on the first issue only' do
      allow(Ability).to receive(:allowed?).and_call_original
      # Newest first, we only want to see the newest checked
      expect(Ability).not_to receive(:allowed?).with(current_user, :read_issue, issues.first)

      post_graphql(query, current_user: current_user)
    end
  end

  context 'when the user does not have access to the issue' do
    it 'returns nil' do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(issues_data).to eq([])
    end
  end

  context 'when there is a confidential issue' do
    let!(:confidential_issue) do
      create(:issue, :confidential, project: project)
    end

    context 'when the user cannot see confidential issues' do
      it 'returns issues without confidential issues' do
        post_graphql(query, current_user: current_user)

        expect(issues_data.size).to eq(2)

        issues_data.each do |issue|
          expect(issue.dig('node', 'confidential')).to eq(false)
        end
      end
    end

    context 'when the user can see confidential issues' do
      it 'returns issues with confidential issues' do
        project.add_developer(current_user)

        post_graphql(query, current_user: current_user)

        expect(issues_data.size).to eq(3)

        confidentials = issues_data.map do |issue|
          issue.dig('node', 'confidential')
        end

        expect(confidentials).to eq([true, false, false])
      end
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:data_path) { [:project, :issues] }

    def pagination_query(params, page_info)
      graphql_query_for(
        'project',
        { 'fullPath' => sort_project.full_path },
        "issues(#{params}) { #{page_info} edges { node { iid dueDate } } }"
      )
    end

    def pagination_results_data(data)
      data.map { |issue| issue.dig('node', 'iid').to_i }
    end

    context 'when sorting by due date' do
      let_it_be(:sort_project) { create(:project, :public) }
      let_it_be(:due_issue1) { create(:issue, project: sort_project, due_date: 3.days.from_now) }
      let_it_be(:due_issue2) { create(:issue, project: sort_project, due_date: nil) }
      let_it_be(:due_issue3) { create(:issue, project: sort_project, due_date: 2.days.ago) }
      let_it_be(:due_issue4) { create(:issue, project: sort_project, due_date: nil) }
      let_it_be(:due_issue5) { create(:issue, project: sort_project, due_date: 1.day.ago) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'DUE_DATE_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [due_issue3.iid, due_issue5.iid, due_issue1.iid, due_issue4.iid, due_issue2.iid] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'DUE_DATE_DESC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [due_issue1.iid, due_issue5.iid, due_issue3.iid, due_issue4.iid, due_issue2.iid] }
        end
      end
    end

    context 'when sorting by relative position' do
      let_it_be(:sort_project) { create(:project, :public) }
      let_it_be(:relative_issue1) { create(:issue, project: sort_project, relative_position: 2000) }
      let_it_be(:relative_issue2) { create(:issue, project: sort_project, relative_position: nil) }
      let_it_be(:relative_issue3) { create(:issue, project: sort_project, relative_position: 1000) }
      let_it_be(:relative_issue4) { create(:issue, project: sort_project, relative_position: nil) }
      let_it_be(:relative_issue5) { create(:issue, project: sort_project, relative_position: 500) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'RELATIVE_POSITION_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [relative_issue5.iid, relative_issue3.iid, relative_issue1.iid, relative_issue4.iid, relative_issue2.iid] }
        end
      end
    end

    context 'when sorting by priority' do
      let_it_be(:sort_project) { create(:project, :public) }
      let_it_be(:early_milestone) { create(:milestone, project: sort_project, due_date: 10.days.from_now) }
      let_it_be(:late_milestone) { create(:milestone, project: sort_project, due_date: 30.days.from_now) }
      let_it_be(:priority_label1) { create(:label, project: sort_project, priority: 1) }
      let_it_be(:priority_label2) { create(:label, project: sort_project, priority: 5) }
      let_it_be(:priority_issue1) { create(:issue, project: sort_project, labels: [priority_label1], milestone: late_milestone) }
      let_it_be(:priority_issue2) { create(:issue, project: sort_project, labels: [priority_label2]) }
      let_it_be(:priority_issue3) { create(:issue, project: sort_project, milestone: early_milestone) }
      let_it_be(:priority_issue4) { create(:issue, project: sort_project) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'PRIORITY_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [priority_issue3.iid, priority_issue1.iid, priority_issue2.iid, priority_issue4.iid] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'PRIORITY_DESC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [priority_issue1.iid, priority_issue3.iid, priority_issue2.iid, priority_issue4.iid] }
        end
      end
    end

    context 'when sorting by label priority' do
      let_it_be(:sort_project) { create(:project, :public) }
      let_it_be(:label1) { create(:label, project: sort_project, priority: 1) }
      let_it_be(:label2) { create(:label, project: sort_project, priority: 5) }
      let_it_be(:label3) { create(:label, project: sort_project, priority: 10) }
      let_it_be(:label_issue1) { create(:issue, project: sort_project, labels: [label1]) }
      let_it_be(:label_issue2) { create(:issue, project: sort_project, labels: [label2]) }
      let_it_be(:label_issue3) { create(:issue, project: sort_project, labels: [label1, label3]) }
      let_it_be(:label_issue4) { create(:issue, project: sort_project) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'LABEL_PRIORITY_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [label_issue3.iid, label_issue1.iid, label_issue2.iid, label_issue4.iid] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'LABEL_PRIORITY_DESC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [label_issue2.iid, label_issue3.iid, label_issue1.iid, label_issue4.iid] }
        end
      end
    end

    context 'when sorting by milestone due date' do
      let_it_be(:sort_project)     { create(:project, :public) }
      let_it_be(:early_milestone)  { create(:milestone, project: sort_project, due_date: 10.days.from_now) }
      let_it_be(:late_milestone)   { create(:milestone, project: sort_project, due_date: 30.days.from_now) }
      let_it_be(:milestone_issue1) { create(:issue, project: sort_project) }
      let_it_be(:milestone_issue2) { create(:issue, project: sort_project, milestone: early_milestone) }
      let_it_be(:milestone_issue3) { create(:issue, project: sort_project, milestone: late_milestone) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'MILESTONE_DUE_ASC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [milestone_issue2.iid, milestone_issue3.iid, milestone_issue1.iid] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { 'MILESTONE_DUE_DESC' }
          let(:first_param)      { 2 }
          let(:expected_results) { [milestone_issue3.iid, milestone_issue2.iid, milestone_issue1.iid] }
        end
      end
    end
  end

  def grab_iids(data = issues_data)
    data.map do |issue|
      issue.dig('node', 'iid').to_i
    end
  end
end
