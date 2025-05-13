# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnableCiJobTokenAllowlistSetting, feature_category: :secrets_management do
  let(:migration) { described_class.new }
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'updates enforce_ci_inbound_job_token_scope_enabled to true' do
      application_settings.create!(enforce_ci_inbound_job_token_scope_enabled: false)
      migration.up

      expect(application_settings.first.enforce_ci_inbound_job_token_scope_enabled).to be true
    end
  end

  describe '#down' do
    it 'updates enforce_ci_inbound_job_token_scope_enabled to false' do
      application_settings.create!(enforce_ci_inbound_job_token_scope_enabled: true)
      migration.down

      expect(application_settings.first.enforce_ci_inbound_job_token_scope_enabled).to be false
    end
  end
end
