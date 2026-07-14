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

  context 'with time spent logged' do
    before do
      create(:timelog, issue: task, time_spent: 3600)
      create(:timelog, issue: task, time_spent: 1800)
    end

    def task_row
      csv.find { |row| row['ID'] == task.id.to_s }
    end

    it 'sums the logged time' do
      expect(task_row['Time Spent']).to eq('1h 30m')
    end
  end

  it 'preloads fields to avoid N+1 queries', :request_store do
    control = ActiveRecord::QueryRecorder.new { subject.csv_data }

    tasks = create_list(:work_item, 3, :task, project: project)
    tasks.each { |task| create(:timelog, issue: task, time_spent: 3600) }

    expect { subject.csv_data }.not_to exceed_query_limit(control)
  end

  describe 'collection iteration strategy' do
    context 'when export_csv_preload_in_batches is enabled' do
      it 'iterates the collection with keyset pagination' do
        expect_next_instance_of(CsvBuilder, kind_of(ExportCsv::KeysetCollection), anything) do |csv_builder|
          expect(csv_builder).to receive(:render).and_call_original
        end

        subject.csv_data
      end
    end

    context 'when export_csv_preload_in_batches is disabled' do
      before do
        stub_feature_flags(export_csv_preload_in_batches: false)
      end

      it 'preloads the whole relation up front and passes no associations to CsvBuilder' do
        expect_next_instance_of(CsvBuilder, kind_of(ActiveRecord::Relation), anything, []) do |csv_builder|
          expect(csv_builder).to receive(:render).and_call_original
        end

        subject.csv_data
      end

      it 'preloads timelogs to avoid a Time Spent N+1', :request_store do
        create(:timelog, issue: create(:work_item, :task, project: project), time_spent: 3600)
        control = ActiveRecord::QueryRecorder.new { described_class.new(WorkItem.all, project).csv_data }

        create_list(:work_item, 3, :task, project: project).each do |task|
          create(:timelog, issue: task, time_spent: 3600)
        end

        expect { described_class.new(WorkItem.all, project).csv_data }.not_to exceed_query_limit(control)
      end
    end
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
