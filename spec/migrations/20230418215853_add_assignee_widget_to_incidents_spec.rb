# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddAssigneeWidgetToIncidents, :migration, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }
  let(:work_item_types) { table(:work_item_types) }

  let(:widget_name) { 'Assignees' }
  let(:work_item_type) { 'Incident' }

  describe '#up' do
    it 'creates widget definition' do
      type = work_item_types.find_by_name_and_namespace_id(work_item_type, nil)
      work_item_definitions.where(work_item_type_id: type, name: widget_name).delete_all if type

      expect { migrate! }.to change { work_item_definitions.count }.by(1)

      type = work_item_types.find_by_name_and_namespace_id(work_item_type, nil)

      expect(work_item_definitions.where(work_item_type_id: type, name: widget_name).count).to eq 1
    end

    it 'logs a warning if the type is missing' do
      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id).and_call_original
      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id)
        .with(work_item_type, nil).and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with(AddAssigneeWidgetToIncidents::FAILURE_MSG)
      migrate!
    end
  end

  describe '#down' do
    it 'removes definitions for widget' do
      migrate!

      expect { migration.down }.to change { work_item_definitions.count }.by(-1)

      type = work_item_types.find_by_name_and_namespace_id(work_item_type, nil)

      expect(work_item_definitions.where(work_item_type_id: type, name: widget_name).count).to eq 0
    end
  end
end
