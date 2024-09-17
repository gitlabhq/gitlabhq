# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanTimeTrackingWidgetDefinitions, feature_category: :team_planning, schema: 20240813065105 do
  let(:work_item_definitions) { table(:work_item_widget_definitions) }
  let(:widget_name) { described_class::WIDGET_NAME }
  let(:widget_enum_value) { described_class::WIDGET_ENUM_VALUE }
  let(:work_item_types) { described_class::WORK_ITEM_TYPES }

  describe '#up', :migration_with_transaction do
    it 'fixes all widget definition names if they had the wrong casing' do
      work_item_definitions.where(widget_type: widget_enum_value).update_all(name: 'wrong name')

      expect do
        migrate!
      end.to change { work_item_definitions.where(widget_type: widget_enum_value).pluck(:name) }
        .from(['wrong name'] * 7).to([widget_name] * 7)
    end

    it 'logs a warning if the type is missing' do
      type_name = work_item_types.first

      allow(described_class::WorkItemType).to receive(:find_by_name).and_call_original
      allow(described_class::WorkItemType).to receive(:find_by_name)
        .with(type_name).and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with("type #{type_name} is missing, not adding widget")
      migrate!
    end
  end
end
