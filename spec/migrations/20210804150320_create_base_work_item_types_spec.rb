# frozen_string_literal: true

require 'spec_helper'
require_migration!('create_base_work_item_types')

RSpec.describe CreateBaseWorkItemTypes, :migration do
  let!(:work_item_types) { table(:work_item_types) }

  it 'creates default data' do
    reversible_migration do |migration|
      migration.before -> {
        # Depending on whether the migration has been run before,
        # the size could be 4, or 0, so we don't set any expectations
      }

      migration.after -> {
        expect(work_item_types.count).to eq 4
        expect(work_item_types.all.pluck(:base_type)).to match_array WorkItem::Type.base_types.values
      }
    end
  end
end
