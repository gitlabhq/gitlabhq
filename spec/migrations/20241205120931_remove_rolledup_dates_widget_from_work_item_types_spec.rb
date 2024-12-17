# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveRolledupDatesWidgetFromWorkItemTypes, :migration, feature_category: :team_planning do
  let(:widget_name) { described_class::WIDGET_NAME }
  let(:work_item_types) { described_class::WORK_ITEM_TYPES }

  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }
  let(:work_item_type_count) { work_item_types.size }
  let(:find_method_name) { :find_by }

  describe '#up', :migration_with_transaction do
    it "removes definitions for widget" do
      migration.down

      expect { migrate! }.to change { work_item_definitions.count }.by(-work_item_type_count)
    end
  end

  describe '#down', :migration_with_transaction do
    before do
      migrate!
    end

    it "creates widget definition in all types" do
      work_item_definitions.where(name: widget_name).delete_all

      expect { migration.down }.to change { work_item_definitions.count }.by(work_item_type_count)
      expect(work_item_definitions.all.pluck(:name)).to include(widget_name)
    end

    it 'logs a warning if the type is missing' do
      type_name = work_item_types.first

      allow(described_class::WorkItemType)
        .to receive(find_method_name)
        .and_call_original
      allow(described_class::WorkItemType)
        .to receive(find_method_name)
        .with(name: type_name)
        .and_return(nil)

      expect(Gitlab::AppLogger)
        .to receive(:warn)
        .with("type #{type_name} is missing, not adding widget")

      migration.down
    end

    context 'when the widget already exists' do
      let(:work_item_types_table) { table(:work_item_types) }

      before do
        work_item_types.each do |type_name|
          type = work_item_types_table.find_by_name(type_name)
          work_item_definitions.create!(
            name: widget_name,
            work_item_type_id: type.id,
            widget_type: described_class::WIDGET_ENUM_VALUE
          )
        end
      end

      it 'upserts the widget definitions and raises no error' do
        expect { migration.down }.to not_change {
          work_item_definitions.where(name: widget_name).count
        }
      end
    end
  end
end
