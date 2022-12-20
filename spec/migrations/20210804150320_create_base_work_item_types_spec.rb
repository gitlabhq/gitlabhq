# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateBaseWorkItemTypes, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let!(:work_item_types) { table(:work_item_types) }

  let(:base_types) do
    {
      issue: 0,
      incident: 1,
      test_case: 2,
      requirement: 3
    }
  end

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  it 'creates default data' do
    # Need to delete all as base types are seeded before entire test suite
    work_item_types.delete_all

    reversible_migration do |migration|
      migration.before -> {
        # Depending on whether the migration has been run before,
        # the size could be 4, or 0, so we don't set any expectations
      }

      migration.after -> {
        expect(work_item_types.count).to eq(4)
        expect(work_item_types.all.pluck(:base_type)).to match_array(base_types.values)
      }
    end
  end
end
