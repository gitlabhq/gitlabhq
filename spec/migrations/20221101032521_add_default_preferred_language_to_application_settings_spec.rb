# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddDefaultPreferredLanguageToApplicationSettings, feature_category: :internationalization do
  let(:application_setting) { table(:application_settings).create! }

  describe "#up" do
    it 'allows to read default_preferred_language field' do
      migrate!

      expect(application_setting.attributes.keys).to include('default_preferred_language')
      expect(application_setting.default_preferred_language).to eq 'en'
    end
  end

  describe "#down" do
    it 'deletes default_preferred_language field' do
      migrate!
      schema_migrate_down!

      expect(application_setting.attributes.keys).not_to include('default_preferred_language')
    end
  end
end
