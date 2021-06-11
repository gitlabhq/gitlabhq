# frozen_string_literal: true

require 'spec_helper'
require_migration!('add_admin_mode_protected_path')

RSpec.describe AddAdminModeProtectedPath do
  subject(:migration) { described_class.new }

  let(:admin_mode_endpoint) { '/admin/session' }
  let(:application_settings) { table(:application_settings) }

  context 'no settings available' do
    it 'makes no changes' do
      expect { migrate! }.not_to change { application_settings.count }
    end
  end

  context 'protected_paths is null' do
    before do
      application_settings.create!(protected_paths: nil)
    end

    it 'makes no changes' do
      expect { migrate! }.not_to change { application_settings.first.protected_paths }
    end
  end

  it 'appends admin mode endpoint' do
    application_settings.create!(protected_paths: '{a,b,c}')

    protected_paths_before = %w[a b c]
    protected_paths_after = protected_paths_before.dup << admin_mode_endpoint

    expect { migrate! }.to change { application_settings.first.protected_paths }.from(protected_paths_before).to(protected_paths_after)
  end

  it 'new default includes admin mode endpoint' do
    settings_before = application_settings.create!

    expect(settings_before.protected_paths).not_to include(admin_mode_endpoint)

    migrate!

    application_settings.reset_column_information
    settings_after = application_settings.create!

    expect(settings_after.protected_paths).to include(admin_mode_endpoint)
  end
end
