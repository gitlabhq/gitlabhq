# frozen_string_literal: true

RSpec.shared_examples(
  'migration that adds widget to work items definitions'
) do |widget_name:, work_item_types:, namespaced: false|
  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }
  let(:work_item_type_count) { work_item_types.size }
  let(:find_method_name) { namespaced ? :find_by_name_and_namespace_id : :find_by_name }

  describe '#up', :migration_with_transaction do
    it "creates widget definition in all types" do
      work_item_definitions.where(name: widget_name).delete_all

      expect { migrate! }.to change { work_item_definitions.count }.by(work_item_type_count)
      expect(work_item_definitions.all.pluck(:name)).to include(widget_name)
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
        expect { migrate! }.to not_change {
          work_item_definitions.where(name: widget_name).count
        }.from(work_item_type_count)
      end
    end
  end

  describe '#down', :migration_with_transaction do
    it "removes definitions for widget" do
      migrate!

      expect { migration.down }.to change { work_item_definitions.count }.by(-work_item_type_count)
      expect(work_item_definitions.all.pluck(:name)).not_to include(widget_name)
    end
  end
end

# Shared examples for testing migration that adds widgets to a work item type
#
# It expects that the following constants are available in the migration
# - `WORK_ITEM_TYPE_ENUM_VALUE`: Int, enum value for the work item type
# - `WIDGET`: Hash, widget definitions (name:, widget_type:)
# - (Old) `WIDGET_ENUM_VALUE`: Int, enum value for the widget type
# - (Old) `WIDGET_NAME`: String, name of the widget
#
# You can override `target_type_enum_value` to explicitly define the work item type enum value
RSpec.shared_examples 'migration that adds widgets to a work item type' do
  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:target_type_enum_value) { described_class::WORK_ITEM_TYPE_ENUM_VALUE }
  let(:widgets) do
    if defined?(described_class::WIDGETS)
      described_class::WIDGETS
    else
      [
        {
          name: described_class::WIDGET_NAME,
          widget_type: described_class::WIDGET_ENUM_VALUE
        }
      ]
    end
  end

  describe '#up', :migration_with_transaction do
    it "adds widgets to work item type", :aggregate_failures do
      expect do
        migrate!
      end.to change { work_item_widget_definitions.count }.by(widgets.size)

      work_item_type = work_item_types.find_by(base_type: target_type_enum_value)
      created_widgets = work_item_widget_definitions.last(widgets.size)

      widgets.each do |widget|
        expect(created_widgets).to include(
          have_attributes(widget.merge(work_item_type_id: work_item_type.id))
        )
      end
    end

    context 'when type does not exist' do
      it 'skips creating the new widget definitions' do
        work_item_types.where(base_type: target_type_enum_value).delete_all

        expect do
          migrate!
        end.to not_change(work_item_widget_definitions, :count)
      end
    end
  end

  describe '#down', :migration_with_transaction do
    it "removes widgets from work item type" do
      migrate!

      expect { schema_migrate_down! }.to change { work_item_widget_definitions.count }.by(-widgets.size)
    end
  end
end
