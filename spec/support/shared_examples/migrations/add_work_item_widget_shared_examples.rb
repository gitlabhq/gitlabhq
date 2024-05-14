# frozen_string_literal: true

RSpec.shared_examples 'migration that adds widget to work items definitions' do |widget_name:, work_item_types:|
  include MigrationHelpers::WorkItemTypesHelper

  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }
  let(:work_item_type_count) { work_item_types.size }

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  describe '#up' do
    it "creates widget definition in all types" do
      work_item_definitions.where(name: widget_name).delete_all

      expect { migrate! }.to change { work_item_definitions.count }.by(work_item_type_count)
      expect(work_item_definitions.all.pluck(:name)).to include(widget_name)
    end

    it 'logs a warning if the type is missing' do
      type_name = work_item_types.first

      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id).and_call_original
      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id)
        .with(type_name, nil).and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with("type #{type_name} is missing, not adding widget")
      migrate!
    end

    context 'when the widget already exists' do
      let(:work_item_types_table) { table(:work_item_types) }

      before do
        work_item_types.each do |type_name|
          type = work_item_types_table.find_by_name_and_namespace_id(type_name, nil)
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

  describe '#down' do
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
  include MigrationHelpers::WorkItemTypesHelper

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

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  before do
    # Database needs to be in a similar state as when the migration was created
    reset_db_state_prior_to_migration
  end

  describe '#up' do
    it "adds widget to work item type", :aggregate_failures do
      expect do
        migrate!
      end.to change { work_item_widget_definitions.count }.by(1)

      work_item_type = work_item_types.find_by(namespace_id: nil, base_type: target_type_enum_value)
      created_widget = work_item_widget_definitions.last

      expect(created_widget).to have_attributes(
        widget_type: described_class::WIDGET_ENUM_VALUE,
        name: described_class::WIDGET_NAME,
        work_item_type_id: work_item_type.id
      )
    end

    context 'when type does not exist' do
      it 'skips creating the new widget definition' do
        work_item_types.where(namespace_id: nil, base_type: base_types[target_type]).delete_all

        expect do
          migrate!
        end.to not_change(work_item_widget_definitions, :count)
      end
    end
  end

  describe '#down' do
    it "removes widget from work item type" do
      migrate!

      expect { schema_migrate_down! }.to change { work_item_widget_definitions.count }.by(-1)
    end
  end

  def reset_db_state_prior_to_migration
    work_item_types.delete_all

    base_types.each do |type_sym, type_enum|
      create_work_item_type!(type_sym.to_s.titleize, type_enum)
    end

    target_type_record = work_item_types.find_by_name(target_type.to_s.titleize)

    widgets = widgets_for_type.map do |widget_name_value, widget_enum_value|
      {
        work_item_type_id: target_type_record.id,
        name: widget_name_value,
        widget_type: widget_enum_value
      }
    end

    # Creating all widgets for the type so the state in the DB is as close as possible to the actual state
    work_item_widget_definitions.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def create_work_item_type!(type_name, type_enum_value)
    work_item_types.create!(
      name: type_name,
      namespace_id: nil,
      base_type: type_enum_value
    )
  end
end
