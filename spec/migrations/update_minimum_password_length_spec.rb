# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateMinimumPasswordLength do
  let(:application_settings) { table(:application_settings) }
  let(:application_setting) do
    application_settings.create!(
      minimum_password_length: ApplicationSetting::DEFAULT_MINIMUM_PASSWORD_LENGTH
    )
  end

  before do
    stub_const('ApplicationSetting::DEFAULT_MINIMUM_PASSWORD_LENGTH', 10)
    allow(Devise.password_length).to receive(:min).and_return(12)
  end

  it 'correctly migrates minimum_password_length' do
    reversible_migration do |migration|
      migration.before -> {
        expect(application_setting.reload.minimum_password_length).to eq(10)
      }

      migration.after -> {
        expect(application_setting.reload.minimum_password_length).to eq(12)
      }
    end
  end
end
