# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDiffLimitsFromColumns, migration: :gitlab_main,
  feature_category: :code_review_workflow do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'backfills legacy diff limits into an empty hash' do
      setting = application_settings.create!(
        diff_limits: {},
        diff_max_patch_bytes: 300_000,
        diff_max_files: 2_000,
        diff_max_lines: 60_000
      )

      migrate!

      expect(setting.reload.diff_limits).to eq(
        'diff_max_patch_bytes' => 300_000,
        'diff_max_files' => 2_000,
        'diff_max_lines' => 60_000
      )
    end

    it 'preserves existing diff limits while backfilling legacy columns' do
      setting = application_settings.create!(
        diff_limits: {
          'diff_max_versions' => 500,
          'diff_max_commits' => 1_000
        },
        diff_max_patch_bytes: 300_000,
        diff_max_files: 2_000,
        diff_max_lines: 60_000
      )

      migrate!

      expect(setting.reload.diff_limits).to eq(
        'diff_max_patch_bytes' => 300_000,
        'diff_max_files' => 2_000,
        'diff_max_lines' => 60_000,
        'diff_max_versions' => 500,
        'diff_max_commits' => 1_000
      )
    end
  end

  describe '#down' do
    it 'removes migrated diff limits while preserving existing diff limits' do
      setting = application_settings.create!(
        diff_limits: {
          'diff_max_patch_bytes' => 300_000,
          'diff_max_files' => 2_000,
          'diff_max_lines' => 60_000,
          'diff_max_versions' => 500,
          'diff_max_commits' => 1_000
        }
      )

      migrate!
      schema_migrate_down!

      expect(setting.reload.diff_limits).to eq(
        'diff_max_versions' => 500,
        'diff_max_commits' => 1_000
      )
    end
  end
end
