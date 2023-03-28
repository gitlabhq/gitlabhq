# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateApplicationSettingsProtectedPaths, :aggregate_failures,
  feature_category: :system_access do
  subject(:migration) { described_class.new }

  let!(:application_settings) { table(:application_settings) }
  let!(:oauth_paths) { %w[/oauth/authorize /oauth/token] }
  let!(:custom_paths) { %w[/foo /bar] }

  let(:default_paths) { application_settings.column_defaults.fetch('protected_paths') }

  before do
    application_settings.create!(protected_paths: custom_paths)
    application_settings.create!(protected_paths: custom_paths + oauth_paths)
    application_settings.create!(protected_paths: custom_paths + oauth_paths.take(1))
  end

  describe '#up' do
    before do
      migrate!
      application_settings.reset_column_information
    end

    it 'removes the OAuth paths from the default value and persisted records' do
      expect(default_paths).not_to include(*oauth_paths)
      expect(default_paths).to eq(described_class::NEW_DEFAULT_PROTECTED_PATHS)
      expect(application_settings.all).to all(have_attributes(protected_paths: custom_paths))
    end
  end

  describe '#down' do
    before do
      migrate!
      schema_migrate_down!
    end

    it 'adds the OAuth paths to the default value and persisted records' do
      expect(default_paths).to include(*oauth_paths)
      expect(default_paths).to eq(described_class::OLD_DEFAULT_PROTECTED_PATHS)
      expect(application_settings.all).to all(have_attributes(protected_paths: custom_paths + oauth_paths))
    end
  end
end
