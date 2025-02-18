# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::WorkItems::Widgets, feature_category: :team_planning do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:type_enum_value) { nil }
  let(:type_enum_values) { [8, 9] }
  let(:single_widget) do
    [
      {
        name: 'Test Widget',
        widget_type: 22
      }
    ]
  end

  let(:multiple_widgets) do
    [
      {
        name: 'Test Widget',
        widget_type: 22
      },
      {
        name: 'Test widget with widget options',
        widget_type: 23,
        widget_options: {
          rollup: false,
          editable: true
        }
      }
    ]
  end

  let(:widgets) { single_widget }

  let(:work_item_type_migration_model) { double('migration_work_item_type') } # rubocop:disable RSpec/VerifiedDoubles -- stub only
  let(:widget_definition_migration_model) { double('migration_widget_definition') } # rubocop:disable RSpec/VerifiedDoubles -- mock only
  let(:work_item_type) { Struct.new(:id, :base_type).new(1, 8) }
  let(:another_work_item_type) { Struct.new(:id, :base_type).new(2, 9) }
  let(:work_item_types_relation) { [work_item_type, another_work_item_type] }

  before do
    allow(migration).to receive_messages(
      migration_work_item_type: work_item_type_migration_model,
      migration_widget_definition: widget_definition_migration_model
    )
    allow(work_item_type_migration_model).to receive(:where)
      .with(base_type: type_enum_values)
      .and_return(work_item_types_relation)
    allow(work_item_type_migration_model).to receive(:where)
      .with(base_type: type_enum_values + [type_enum_value].compact)
      .and_return(work_item_types_relation)
    allow(work_item_type_migration_model).to receive(:where)
      .with(base_type: [])
      .and_return([])
  end

  describe '#add_widget_definitions' do
    shared_examples 'properly executed up migration' do
      it 'upserts widget definitions' do
        expected_widgets = work_item_types_relation.flat_map do |type|
          widgets.map { |w| { work_item_type_id: type.id, widget_options: nil }.merge(w) }
        end

        expect(migration).not_to receive(:say)

        expect(widget_definition_migration_model).to receive(:upsert_all)
          .with(expected_widgets, on_duplicate: :skip)

        migration.add_widget_definitions(
          type_enum_value: type_enum_value,
          type_enum_values: type_enum_values,
          widgets: widgets
        )
      end
    end

    it_behaves_like 'properly executed up migration'

    context 'when there is more than one widget' do
      let(:widgets) { multiple_widgets }

      it_behaves_like 'properly executed up migration'
    end

    context 'when work item types do not exist' do
      let(:work_item_types_relation) { [] }

      it 'logs a message for all missing types and does not upsert' do
        type_enum_values.each do |type_enum_value|
          expect(migration).to receive(:say).with(/Work item type with enum value #{type_enum_value} does not exist/)
        end

        expect(widget_definition_migration_model).not_to receive(:upsert_all)

        migration.add_widget_definitions(type_enum_values: type_enum_values, widgets: widgets)
      end
    end

    context 'when two types are passed but only one is found' do
      let(:work_item_types_relation) { [work_item_type] }

      it 'logs a message for the missing type and upserts for the found type' do
        expect(migration).to receive(:say).with(/Work item type with enum value 9 does not exist/)
        expect(widget_definition_migration_model).to receive(:upsert_all)
          .with([{ work_item_type_id: work_item_type.id, widget_options: nil }
          .merge(single_widget.first)], on_duplicate: :skip)

        migration.add_widget_definitions(type_enum_values: type_enum_values, widgets: widgets)
      end
    end

    context 'when only type_enum_value is provided' do
      let(:type_enum_value) { 8 }
      let(:type_enum_values) { [] }

      it_behaves_like 'properly executed up migration'
    end
  end

  describe '#remove_widget_definitions' do
    shared_examples 'properly executed down migration' do
      it 'deletes widget definitions' do
        widget_definition_relation = double('widget_definition_relation') # rubocop:disable RSpec/VerifiedDoubles -- mock only
        expect(widget_definition_migration_model).to receive(:where)
          .with(work_item_type_id: work_item_types_relation.pluck(:id), widget_type: widgets.pluck(:widget_type))
          .and_return(widget_definition_relation)

        expect(widget_definition_relation).to receive(:delete_all)

        migration.remove_widget_definitions(
          type_enum_value: type_enum_value,
          type_enum_values: type_enum_values,
          widgets: widgets
        )
      end
    end

    it_behaves_like 'properly executed down migration'

    context 'when there is more than one widget' do
      let(:widgets) { multiple_widgets }

      it_behaves_like 'properly executed down migration'
    end

    context 'when work item type does not exist' do
      let(:work_item_types_relation) { [] }

      it 'logs a message for all missing types and does not delete' do
        type_enum_values.each do |type_enum_value|
          expect(migration).to receive(:say).with(/Work item type with enum value #{type_enum_value} does not exist/)
        end

        expect(widget_definition_migration_model).not_to receive(:where)

        migration.remove_widget_definitions(type_enum_values: type_enum_values, widgets: widgets)
      end
    end

    context 'when two types are passed but only one is found' do
      let(:work_item_types_relation) { [work_item_type] }

      it 'logs a message for the missing type and deletes widgets for the found type' do
        expect(migration).to receive(:say).with(/Work item type with enum value 9 does not exist/)

        widget_definition_relation = double('widget_definition_relation') # rubocop:disable RSpec/VerifiedDoubles -- mock only
        expect(widget_definition_migration_model).to receive(:where)
          .with(work_item_type_id: [work_item_type.id], widget_type: widgets.pluck(:widget_type))
          .and_return(widget_definition_relation)

        expect(widget_definition_relation).to receive(:delete_all)

        migration.remove_widget_definitions(type_enum_values: type_enum_values, widgets: widgets)
      end
    end

    context 'when only type_enum_value is provided' do
      let(:type_enum_value) { 8 }
      let(:type_enum_values) { [] }

      it_behaves_like 'properly executed down migration'
    end
  end
end
