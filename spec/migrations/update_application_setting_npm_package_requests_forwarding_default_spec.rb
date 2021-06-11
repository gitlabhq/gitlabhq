# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateApplicationSettingNpmPackageRequestsForwardingDefault do
  # Create test data - pipeline and CI/CD jobs.
  let(:application_settings) { table(:application_settings) }

  before do
    application_settings.create!(npm_package_requests_forwarding: false)
  end

  # Test just the up migration.
  it 'correctly migrates the application setting' do
    expect { migrate! }.to change { current_application_setting }.from(false).to(true)
  end

  # Test a reversible migration.
  it 'correctly migrates up and down the application setting' do
    reversible_migration do |migration|
      # Expectations will run before the up migration,
      # and then again after the down migration
      migration.before -> {
        expect(current_application_setting).to eq false
      }

      # Expectations will run after the up migration.
      migration.after -> {
        expect(current_application_setting).to eq true
      }
    end
  end

  def current_application_setting
    ApplicationSetting.current_without_cache.npm_package_requests_forwarding
  end
end
