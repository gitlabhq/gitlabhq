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

# Setup context for shared examples
# - migration that adds widgets to a work item type
# - migration that removes widgets from work item types
RSpec.shared_context 'with work item widget migration setup' do
  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:target_type_enum_values) do
    if defined?(described_class::WORK_ITEM_TYPE_ENUM_VALUES)
      Array(described_class::WORK_ITEM_TYPE_ENUM_VALUES)
    else
      Array(described_class::WORK_ITEM_TYPE_ENUM_VALUE)
    end
  end

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
end

# Shared examples for testing migration that adds widgets to work item types
#
# It expects that the following constants are available in the migration
# - `WORK_ITEM_TYPE_ENUM_VALUES`: Array, enum values for the work item types
# - `WIDGETS`: Array of Hash, widget definitions (name:, widget_type:)
# - (Old) `WORK_ITEM_TYPE_ENUM_VALUE`: Int, enum value for the work item type
# - (Old) `WIDGET_ENUM_VALUE`: Int, enum value for the widget type
# - (Old) `WIDGET_NAME`: String, name of the widget
#
# You can override `target_type_enum_values` to explicitly define the work item type enum value
RSpec.shared_examples 'migration that adds widgets to a work item type' do
  include_context 'with work item widget migration setup'

  describe '#up', :migration_with_transaction do
    it_behaves_like 'adds widgets to work item types'
  end

  describe '#down', :migration_with_transaction do
    it_behaves_like 'removes widgets from work item types'
  end
end

# Shared examples for testing migration that removes widgets from a work item types
#
# It expects that the following constants are available in the migration
# - `WORK_ITEM_TYPE_ENUM_VALUES`: Array, enum values for the work item types
# - `WIDGETS`: Array of Hash, widget definitions (name:, widget_type:)
# - (Old) `WORK_ITEM_TYPE_ENUM_VALUE`: Int, enum value for the work item type
# - (Old) `WIDGET_ENUM_VALUE`: Int, enum value for the widget type
# - (Old) `WIDGET_NAME`: String, name of the widget
#
# You can override `target_type_enum_values` to explicitly define the work item type enum value
RSpec.shared_examples 'migration that removes widgets from work item types' do
  include_context 'with work item widget migration setup'

  describe '#up', :migration_with_transaction do
    it_behaves_like 'removes widgets from work item types' do
      let(:asserted_migration_method_sym) { :migrate! }
    end
  end

  describe '#down', :migration_with_transaction do
    it_behaves_like 'adds widgets to work item types' do
      let(:asserted_migration_method_sym) { :schema_migrate_down! }
    end
  end
end

RSpec.shared_examples 'adds widgets to work item types' do
  let(:asserted_migration_method_sym) { :migrate! }

  before do
    # Ensure we run up migration, so we can roll back
    migrate! if asserted_migration_method_sym == :schema_migrate_down!
  end

  it "adds widgets to work item types", :aggregate_failures do
    expect do
      send(asserted_migration_method_sym)
    end.to change { work_item_widget_definitions.count }.by(widgets.size * target_type_enum_values.size)
    work_item_types_with_widgets = target_type_enum_values.map do |enum_value|
      work_item_types.find_by(base_type: enum_value)
    end

    created_widgets = work_item_widget_definitions.where(
      work_item_type_id: work_item_types_with_widgets.map(&:id)
    )
    work_item_types_with_widgets.each do |work_item_type|
      widgets.each do |widget|
        expected_attributes = {
          work_item_type_id: work_item_type.id,
          widget_type: widget[:widget_type],
          name: widget[:name],
          # Hashes from json from DB have string keys
          widget_options: widget[:widget_options] ? widget[:widget_options].stringify_keys : nil
        }

        expect(created_widgets).to include(
          have_attributes(expected_attributes)
        )
      end
    end
  end

  context 'when types do not exist' do
    it 'skips creating the new widget definitions' do
      work_item_types.where(base_type: target_type_enum_values).delete_all

      expect do
        migrate!
      end.to not_change(work_item_widget_definitions, :count)
    end
  end
end

RSpec.shared_examples 'removes widgets from work item types' do
  let(:asserted_migration_method_sym) { :schema_migrate_down! }

  before do
    # Ensure we run up migration, so we can roll back
    migrate! if asserted_migration_method_sym == :schema_migrate_down!
  end

  it "removes widgets from work item type" do
    expect { send(asserted_migration_method_sym) }.to change { work_item_widget_definitions.count }.by(
      -(widgets.size * target_type_enum_values.size)
    )
  end
end
