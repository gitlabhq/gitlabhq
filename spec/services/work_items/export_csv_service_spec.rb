# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ExportCsvService, :with_license, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:work_item_1) { create(:work_item, project: project) }
  let_it_be(:work_item_2) { create(:work_item, :incident, project: project) }

  subject { described_class.new(WorkItem.all, project) }

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  context 'when import_export_work_items_csv flag is not enabled' do
    before do
      stub_feature_flags(import_export_work_items_csv: false)
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
    expect(csv.count).to eq(2)
  end

  specify 'iid' do
    expect(csv[0]['Id']).to eq work_item_1.iid.to_s
  end

  specify 'title' do
    expect(csv[0]['Title']).to eq work_item_1.title
  end

  specify 'type' do
    expect(csv[0]['Type']).to eq('Issue')
    expect(csv[1]['Type']).to eq('Incident')
  end

  specify 'author name' do
    expect(csv[0]['Author']).to eq(work_item_1.author_name)
  end

  specify 'author username' do
    expect(csv[0]['Author Username']).to eq(work_item_1.author.username)
  end

  specify 'created_at' do
    expect(csv[0]['Created At (UTC)']).to eq(work_item_1.created_at.to_s(:csv))
  end

  it 'preloads fields to avoid N+1 queries' do
    control = ActiveRecord::QueryRecorder.new { subject.csv_data }

    create(:work_item, :task, project: project)

    expect { subject.csv_data }.not_to exceed_query_limit(control)
  end

  it_behaves_like 'a service that returns invalid fields from selection'
end
