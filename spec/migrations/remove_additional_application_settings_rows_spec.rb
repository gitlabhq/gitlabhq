# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveAdditionalApplicationSettingsRows do
  let(:application_settings) { table(:application_settings) }

  it 'removes additional rows from application settings' do
    3.times { application_settings.create! }
    latest_settings = application_settings.create!

    disable_migrations_output { migrate! }

    expect(application_settings.count).to eq(1)
    expect(application_settings.first).to eq(latest_settings)
  end

  it 'leaves only row in application_settings' do
    latest_settings = application_settings.create!

    disable_migrations_output { migrate! }

    expect(application_settings.first).to eq(latest_settings)
  end
end
