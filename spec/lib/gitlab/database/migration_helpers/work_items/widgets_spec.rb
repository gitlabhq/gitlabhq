# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::WorkItems::Widgets, feature_category: :team_planning do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:type_enum_value) { 8 }
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
        name: 'Another Test Widget',
        widget_type: 23
      }
    ]
  end

  let(:widgets) { single_widget }

  let(:work_item_type_migration_model) { double('migration_work_item_type') } # rubocop:disable RSpec/VerifiedDoubles -- stub only
  let(:widget_definition_migration_model) { double('migration_widget_definition') } # rubocop:disable RSpec/VerifiedDoubles -- mock only
  let(:work_item_type) { double('work_item_type', id: 1) } # rubocop:disable RSpec/VerifiedDoubles -- stub only

  before do
    allow(migration).to receive_messages(
      migration_work_item_type: work_item_type_migration_model,
      migration_widget_definition: widget_definition_migration_model
    )
  end

  describe '#add_widget_definitions' do
    shared_examples 'properly executed up migration' do
      it 'upserts widget definitions' do
        expected_widgets = widgets.map { |w| w.merge(work_item_type_id: work_item_type.id) }

        expect(widget_definition_migration_model).to receive(:upsert_all)
          .with(expected_widgets, on_duplicate: :skip)

        migration.add_widget_definitions(type_enum_value: type_enum_value, widgets: widgets)
      end
    end

    context 'when work item type exists' do
      before do
        allow(work_item_type_migration_model).to receive(:find_by)
          .with(base_type: type_enum_value)
          .and_return(work_item_type)
      end

      it_behaves_like 'properly executed up migration'

      context 'when there is more than one widget' do
        let(:widgets) { multiple_widgets }

        it_behaves_like 'properly executed up migration'
      end
    end

    context 'when work item type does not exist' do
      before do
        allow(work_item_type_migration_model).to receive(:find_by)
          .with(base_type: type_enum_value)
          .and_return(nil)
      end

      it 'logs a message and does not upsert' do
        expect(migration).to receive(:say).with(/Work item type with enum value 8 does not exist/)
        expect(widget_definition_migration_model).not_to receive(:upsert_all)

        migration.add_widget_definitions(type_enum_value: type_enum_value, widgets: widgets)
      end
    end
  end

  describe '#remove_widget_definitions' do
    shared_examples 'properly executed down migration' do
      it 'deletes widget definitions' do
        widget_definition_relation = double('widget_definition_relation') # rubocop:disable RSpec/VerifiedDoubles -- mock only
        expect(widget_definition_migration_model).to receive(:where)
          .with(work_item_type_id: work_item_type.id, widget_type: widgets.pluck(:widget_type))
          .and_return(widget_definition_relation)

        expect(widget_definition_relation).to receive(:delete_all)

        migration.remove_widget_definitions(type_enum_value: type_enum_value, widgets: widgets)
      end
    end

    context 'when work item type exists' do
      before do
        allow(work_item_type_migration_model).to receive(:find_by)
          .with(base_type: type_enum_value)
          .and_return(work_item_type)
      end

      it_behaves_like 'properly executed down migration'

      context 'when there is more than one widget' do
        let(:widgets) { multiple_widgets }

        it_behaves_like 'properly executed down migration'
      end
    end

    context 'when work item type does not exist' do
      before do
        allow(work_item_type_migration_model).to receive(:find_by)
          .with(base_type: type_enum_value)
          .and_return(nil)
      end

      it 'logs a message and does not delete' do
        expect(migration).to receive(:say).with(/Work item type with enum value 8 does not exist/)
        expect(widget_definition_migration_model).not_to receive(:upsert_all)

        migration.remove_widget_definitions(type_enum_value: type_enum_value, widgets: widgets)
      end
    end
  end
end
