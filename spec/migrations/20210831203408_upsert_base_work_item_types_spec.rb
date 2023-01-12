# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpsertBaseWorkItemTypes, :migration, feature_category: :team_planning do
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

  append_after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  context 'when no default types exist' do
    it 'creates default data' do
      # Need to delete all as base types are seeded before entire test suite
      work_item_types.delete_all

      expect(work_item_types.count).to eq(0)

      reversible_migration do |migration|
        migration.before -> {
          # Depending on whether the migration has been run before,
          # the size could be 4, or 0, so we don't set any expectations
          # as we don't delete base types on migration reverse
        }

        migration.after -> {
          expect(work_item_types.count).to eq(4)
          expect(work_item_types.all.pluck(:base_type)).to match_array(base_types.values)
        }
      end
    end
  end

  context 'when default types already exist' do
    it 'does not create default types again' do
      # Database needs to be in a similar state as when this migration was created
      work_item_types.delete_all
      work_item_types.find_or_create_by!(name: 'Issue', namespace_id: nil, base_type: base_types[:issue], icon_name: 'issue-type-issue')
      work_item_types.find_or_create_by!(name: 'Incident', namespace_id: nil, base_type: base_types[:incident], icon_name: 'issue-type-incident')
      work_item_types.find_or_create_by!(name: 'Test Case', namespace_id: nil, base_type: base_types[:test_case], icon_name: 'issue-type-test-case')
      work_item_types.find_or_create_by!(name: 'Requirement', namespace_id: nil, base_type: base_types[:requirement], icon_name: 'issue-type-requirements')

      reversible_migration do |migration|
        migration.before -> {
          expect(work_item_types.all.pluck(:base_type)).to match_array(base_types.values)
        }

        migration.after -> {
          expect(work_item_types.count).to eq(4)
          expect(work_item_types.all.pluck(:base_type)).to match_array(base_types.values)
        }
      end
    end
  end
end
