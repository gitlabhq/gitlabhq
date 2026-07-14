# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SeedCiLintLimitPerUserFromPipelineLimit, migration: :gitlab_main, feature_category: :pipeline_composition do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'seeds ci_lint_limit_per_user from pipeline_limit_per_user when ci_lint is unset', :aggregate_failures do
      setting = application_settings.create!(rate_limits: { 'pipeline_limit_per_user' => 30 })

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(30)
      expect(setting.rate_limits['pipeline_limit_per_user']).to eq(30)
    end

    it 'treats an explicit zero ci_lint as unset and seeds it' do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 30, 'ci_lint_limit_per_user' => 0 }
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(30)
    end

    it 'does not seed when pipeline_limit_per_user is zero' do
      setting = application_settings.create!(rate_limits: { 'pipeline_limit_per_user' => 0 })

      migrate!

      setting.reload
      expect(setting.rate_limits).not_to have_key('ci_lint_limit_per_user')
    end

    it 'does not seed when pipeline_limit_per_user is absent' do
      setting = application_settings.create!(rate_limits: {})

      migrate!

      setting.reload
      expect(setting.rate_limits).not_to have_key('ci_lint_limit_per_user')
    end

    it 'does not overwrite an already configured non-zero ci_lint_limit_per_user' do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 30, 'ci_lint_limit_per_user' => 5 }
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(5)
    end

    it 'preserves other rate_limits keys', :aggregate_failures do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 30, 'other_limit' => 99 }
      )

      migrate!

      setting.reload
      expect(setting.rate_limits['ci_lint_limit_per_user']).to eq(30)
      expect(setting.rate_limits['other_limit']).to eq(99)
    end
  end

  describe '#down' do
    it 'removes a seeded ci_lint_limit_per_user on rollback', :aggregate_failures do
      setting = application_settings.create!(rate_limits: { 'pipeline_limit_per_user' => 30 })

      migrate!
      expect(setting.reload.rate_limits['ci_lint_limit_per_user']).to eq(30)

      schema_migrate_down!

      setting.reload
      expect(setting.rate_limits).not_to have_key('ci_lint_limit_per_user')
      expect(setting.rate_limits['pipeline_limit_per_user']).to eq(30)
    end

    it 'removes the ci_lint_limit_per_user key even when it was independently configured' do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 30, 'ci_lint_limit_per_user' => 5 }
      )

      migrate!
      schema_migrate_down!

      setting.reload
      expect(setting.rate_limits).not_to have_key('ci_lint_limit_per_user')
    end

    it 'preserves other rate_limits keys on rollback', :aggregate_failures do
      setting = application_settings.create!(
        rate_limits: { 'pipeline_limit_per_user' => 30, 'other_limit' => 99 }
      )

      migrate!
      schema_migrate_down!

      setting.reload
      expect(setting.rate_limits).not_to have_key('ci_lint_limit_per_user')
      expect(setting.rate_limits['pipeline_limit_per_user']).to eq(30)
      expect(setting.rate_limits['other_limit']).to eq(99)
    end
  end
end
