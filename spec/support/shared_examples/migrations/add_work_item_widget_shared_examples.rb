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

    it 'logs a warning if the type is missing' do
      type_name = work_item_types.first

      allow(described_class::WorkItemType).to receive(find_method_name).and_call_original
      allow(described_class::WorkItemType).to receive(find_method_name)
        .with(type_name, nil).and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with("type #{type_name} is missing, not adding widget")
      migrate!
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

# Shared examples for testing migration that adds a single widget to a work item type
#
# It expects the following variables
# - `target_type_enum_value`: Int, enum value for the target work item type, typically defined in the migration
#                             as a constant
# - `target_type`: Symbol, the target type's name
# - `additional_types`: Hash (optional), name of work item types and their corresponding enum value that are defined
#                       at the time the migration was created but are missing from `base_types`.
# - `widgets_for_type`: Hash, name of the widgets included in the target type with their corresponding enum value
RSpec.shared_examples 'migration that adds a widget to a work item type' do
  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:additional_base_types) { try(:additional_types) || {} }
  let(:base_types) do
    {
      issue: 0,
      incident: 1,
      test_case: 2,
      requirement: 3,
      task: 4,
      objective: 5,
      key_result: 6,
      epic: 7
    }.merge!(additional_base_types)
  end

  describe '#up', :migration_with_transaction do
    it "adds widget to work item type", :aggregate_failures do
      expect do
        migrate!
      end.to change { work_item_widget_definitions.count }.by(1)

      work_item_type = work_item_types.find_by(base_type: target_type_enum_value)
      created_widget = work_item_widget_definitions.last

      expect(created_widget).to have_attributes(
        widget_type: described_class::WIDGET_ENUM_VALUE,
        name: described_class::WIDGET_NAME,
        work_item_type_id: work_item_type.id
      )
    end

    context 'when type does not exist' do
      it 'skips creating the new widget definition' do
        work_item_types.where(base_type: base_types[target_type]).delete_all

        expect do
          migrate!
        end.to not_change(work_item_widget_definitions, :count)
      end
    end
  end

  describe '#down', :migration_with_transaction do
    it "removes widget from work item type" do
      migrate!

      expect { schema_migrate_down! }.to change { work_item_widget_definitions.count }.by(-1)
    end
  end
end
