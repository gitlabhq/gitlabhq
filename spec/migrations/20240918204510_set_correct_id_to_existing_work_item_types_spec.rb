# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetCorrectIdToExistingWorkItemTypes, :migration_with_transaction, feature_category: :team_planning do
  let(:work_item_types) { table(:work_item_types) }

  it 'sets the correct id for every record in the table', :aggregate_failures do
    reversible_migration do |migration|
      migration.before -> {
        expect(work_item_types.pluck(:correct_id)).to all(be_zero)
      }

      migration.after -> {
        described_class::WORK_ITEM_TYPES.each_value do |type_data|
          expect(work_item_types.find_by(base_type: type_data[:enum_value]).correct_id).to eq(type_data[:correct_id])
        end
      }
    end
  end
end
