# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetCiLintLimitPerUser, migration: :gitlab_main, feature_category: :pipeline_composition do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'resets a value seeded from pipeline_limit_per_user', :aggregate_failures do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 2000, 'ci_lint_limit_per_user' => 2000 }
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(0)
      expect(setting.rate_limits['pipeline_limit_per_user']).to eq(2000)
    end

    it 'resets a value an administrator configured' do
      setting = application_settings.create!(rate_limits: { 'ci_lint_limit_per_user' => 500 })

      migrate!

      expect(setting.reload.rate_limits['ci_lint_limit_per_user']).to eq(0)
    end

    it 'leaves an existing zero in place' do
      setting = application_settings.create!(rate_limits: { 'ci_lint_limit_per_user' => 0 })

      migrate!

      expect(setting.reload.rate_limits['ci_lint_limit_per_user']).to eq(0)
    end

    it 'does not add the key when it is absent' do
      setting = application_settings.create!(rate_limits: { 'pipeline_limit_per_user' => 2000 })

      migrate!

      expect(setting.reload.rate_limits).not_to have_key('ci_lint_limit_per_user')
    end

    it 'preserves other rate_limits keys', :aggregate_failures do
      setting = application_settings.create!(
        rate_limits: { 'ci_lint_limit_per_user' => 500, 'other_limit' => 99 }
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(0)
      expect(setting.rate_limits['other_limit']).to eq(99)
    end
  end

  describe '#down' do
    it 'does not restore the previous value' do
      setting = application_settings.create!(rate_limits: { 'ci_lint_limit_per_user' => 500 })

      migrate!
      schema_migrate_down!

      expect(setting.reload.rate_limits['ci_lint_limit_per_user']).to eq(0)
    end
  end
end
