# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateWeightWidgetDefinitions, :migration_with_transaction, feature_category: :team_planning do
  let(:work_item_types) { table(:work_item_types) }
  let(:widget_definitions) { table(:work_item_widget_definitions) }

  it 'updates existing weight definitions and adds a new one for epics' do
    epic_type = work_item_types.find_by_base_type_and_namespace_id(described_class::EPIC_TYPE_ENUM, nil)

    reversible_migration do |migration|
      weight_widgets = widget_definitions.where(widget_type: described_class::WEIGHT_WIDGET_TYPE_ENUM)

      migration.before -> {
        expect(weight_widgets.map(&:widget_options)).to all(be_nil)

        expect(weight_widgets.where(work_item_type_id: epic_type.id).exists?).to eq(false)
      }

      migration.after -> {
        epic_weight_widget = weight_widgets.find_by(work_item_type_id: epic_type.id)
        expect(epic_weight_widget.widget_options).to eq({ 'editable' => false, 'rollup' => true })

        other_weight_widgets = weight_widgets.where.not(id: epic_weight_widget.id)
        expect(other_weight_widgets.map(&:widget_options)).to all(eq({ 'editable' => true, 'rollup' => false }))
      }
    end
  end
end
