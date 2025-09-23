# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ExportCsvService, :with_license, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_milestone) { create(:milestone, project: project, title: 'Test Project Milestone') }
  let_it_be(:parent_work_item) { create(:work_item, description: 'parent', project: project) }
  let_it_be_with_reload(:task) do
    create(:work_item, :task, description: 'test', project: project, milestone: project_milestone)
  end

  let_it_be(:incident) { create(:work_item, :incident, project: project) }
  let_it_be(:work_item_link) { create(:parent_link, work_item: task, work_item_parent: parent_work_item) }

  subject { described_class.new(WorkItem.all, project) }

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  context 'when work_items_project_issues_list flag is not enabled' do
    before do
      stub_feature_flags(work_items_project_issues_list: false)
    end

    it 'renders an error' do
      expect { subject.csv_data }.to raise_error(described_class::NotAvailableError)
    end
  end

  it 'renders csv to string' do
    expect(subject.csv_data).to be_a String
  end

  describe '#email' do
    it 'emails csv' do
      expect { subject.email(user) }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
    end
  end

  it 'returns two work items' do
    expect(csv.count).to eq(3)
  end

  specify 'id' do
    expect(csv[1]['ID']).to eq task.id.to_s
  end

  specify 'iid' do
    expect(csv[1]['IID']).to eq task.iid.to_s
  end

  specify 'title' do
    expect(csv[1]['Title']).to eq task.title
  end

  specify 'url' do
    expect(csv[1]['URL']).to eq Gitlab::Routing.url_helpers.project_work_item_url(task.project, task)
  end

  specify 'type' do
    expect(csv[0]['Type']).to eq('Issue')
    expect(csv[1]['Type']).to eq('Task')
    expect(csv[2]['Type']).to eq('Incident')
  end

  specify 'author name' do
    expect(csv[1]['Author']).to eq(task.author_name)
  end

  specify 'author username' do
    expect(csv[1]['Author Username']).to eq(task.author.username)
  end

  specify 'assignees data' do
    expect(csv[1]['Assignee']).to eq("")
    expect(csv[1]['Assignee Username']).to eq("")
  end

  specify 'labels' do
    expect(csv[1]['Labels']).to eq("")
  end

  specify 'created_at and updated_at' do
    expect(csv[1]['Created At (UTC)']).to eq(task.created_at.to_fs(:csv))
    expect(csv[1]['Updated At (UTC)']).to eq(task.updated_at.to_fs(:csv))
  end

  specify 'description' do
    expect(csv[1]['Description']).to be_present
    expect(csv[1]['Description']).to eq("test")
  end

  specify 'base metadata' do
    expect(csv[1]['State']).to eq(task.closed? ? "Closed" : "Open")
    expect(csv[1]['Confidential']).to eq("No")
    expect(csv[1]['Locked']).to eq("No")
  end

  specify 'start_and_due_date' do
    expect(csv[1]['Start Date']).to eq(task.get_widget(:start_and_due_date).start_date)
    expect(csv[1]['Due Date']).to eq(task.get_widget(:start_and_due_date).due_date)
  end

  specify 'milestone' do
    expect(csv[1]['Milestone']).to eq('Test Project Milestone')
  end

  specify 'parent data' do
    expect(csv[1]['Parent ID']).to eq(task.get_widget(:hierarchy).parent.id.to_s)
    expect(csv[1]['Parent IID']).to eq(task.get_widget(:hierarchy).parent.iid.to_s)
    expect(csv[1]['Parent Title']).to eq(task.get_widget(:hierarchy).parent.title)
  end

  specify 'time tracking' do
    expect(csv[1]['Time Estimate']).to be_nil
    expect(csv[1]['Time Spent']).to be_nil
  end

  it 'preloads fields to avoid N+1 queries' do
    control = ActiveRecord::QueryRecorder.new { subject.csv_data }

    create(:work_item, :task, project: project)

    expect { subject.csv_data }.not_to exceed_query_limit(control).with_threshold(1)
  end

  it_behaves_like 'a service that returns invalid fields from selection'

  # TODO - once we have a UI for this feature
  # we can turn these into feature specs.
  # more info at: https://gitlab.com/gitlab-org/gitlab/-/issues/396943
  context 'when importing an exported file' do
    context 'for work item of type issue' do
      it_behaves_like 'a exported file that can be imported' do
        let_it_be(:user) { create(:user) }
        let_it_be(:origin_project) { create(:project) }
        let_it_be(:target_project) { create(:project) }
        let_it_be(:work_item) { create(:work_item, project: origin_project) }

        let(:expected_matching_fields) { %w[title work_item_type] }
      end
    end
  end
end
