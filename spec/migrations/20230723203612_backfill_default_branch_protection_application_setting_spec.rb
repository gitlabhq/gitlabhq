# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDefaultBranchProtectionApplicationSetting, :migration, feature_category: :database do
  let(:application_settings_table) { table(:application_settings) }

  before do
    5.times do |branch_protection|
      application_settings_table.create!(default_branch_protection: branch_protection,
        default_branch_protection_defaults: {})
    end
  end

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        5.times do |branch_protection|
          expect(migrated_attribute(branch_protection)).to eq({})
        end
      }

      migration.after -> {
        expect(migrated_attribute(0)).to eq({ "allow_force_push" => true,
                                              "allowed_to_merge" => [{ "access_level" => 30 }],
                                              "allowed_to_push" => [{ "access_level" => 30 }] })
        expect(migrated_attribute(1)).to eq({ "allow_force_push" => false,
                                              "allowed_to_merge" => [{ "access_level" => 30 }],
                                              "allowed_to_push" => [{ "access_level" => 30 }] })
        expect(migrated_attribute(2)).to eq({ "allow_force_push" => false,
                                              "allowed_to_merge" => [{ "access_level" => 40 }],
                                              "allowed_to_push" => [{ "access_level" => 40 }] })
        expect(migrated_attribute(3)).to eq({ "allow_force_push" => true,
                                              "allowed_to_merge" => [{ "access_level" => 30 }],
                                              "allowed_to_push" => [{ "access_level" => 40 }] })
        expect(migrated_attribute(4)).to eq({ "allow_force_push" => true,
                                              "allowed_to_merge" => [{ "access_level" => 30 }],
                                              "allowed_to_push" => [{ "access_level" => 40 }],
                                              "developer_can_initial_push" => true })
      }
    end
  end

  def migrated_attribute(branch_protection)
    application_settings_table
      .where(default_branch_protection: branch_protection)
      .last.default_branch_protection_defaults
  end
end
