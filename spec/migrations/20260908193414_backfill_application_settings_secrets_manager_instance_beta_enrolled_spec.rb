# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillApplicationSettingsSecretsManagerInstanceBetaEnrolled,
  migration: :gitlab_main,
  feature_category: :secrets_management do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'marks an enrolled instance as beta-enrolled' do
      setting = application_settings.create!(secrets_manager_instance_enrolled: true)

      migrate!

      expect(setting.reload.secrets_manager_instance_beta_enrolled).to be(true)
    end

    it 'leaves an unenrolled instance unmarked' do
      setting = application_settings.create!(secrets_manager_instance_enrolled: false)

      migrate!

      expect(setting.reload.secrets_manager_instance_beta_enrolled).to be(false)
    end
  end
end
