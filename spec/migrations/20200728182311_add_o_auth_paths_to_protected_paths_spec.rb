# frozen_string_literal: true

require 'spec_helper'
require_migration!('add_o_auth_paths_to_protected_paths')

RSpec.describe AddOAuthPathsToProtectedPaths do
  subject(:migration) { described_class.new }

  let(:application_settings) { table(:application_settings) }
  let(:new_paths) do
    [
      '/oauth/authorize',
      '/oauth/token'
    ]
  end

  it 'appends new OAuth paths' do
    application_settings.create!

    protected_paths_before = application_settings.first.protected_paths
    protected_paths_after = protected_paths_before + new_paths

    expect { migrate! }.to change { application_settings.first.protected_paths }.from(protected_paths_before).to(protected_paths_after)
  end

  it 'new default includes new paths' do
    settings_before = application_settings.create!

    expect(settings_before.protected_paths).not_to include(*new_paths)

    migrate!

    application_settings.reset_column_information
    settings_after = application_settings.create!

    expect(settings_after.protected_paths).to include(*new_paths)
  end

  it 'does not change the value when the new paths are already included' do
    application_settings.create!(protected_paths: %w(/users/sign_in /users/password) + new_paths)

    expect { migrate! }.not_to change { application_settings.first.protected_paths }
  end

  it 'adds one value when the other is already present' do
    application_settings.create!(protected_paths: %W(/users/sign_in /users/password #{new_paths.first}))

    migrate!

    expect(application_settings.first.protected_paths).to include(new_paths.second)
  end
end
