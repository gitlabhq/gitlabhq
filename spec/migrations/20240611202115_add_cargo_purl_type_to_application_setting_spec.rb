# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddCargoPurlTypeToApplicationSetting, feature_category: :software_composition_analysis do
  let(:settings) { table(:application_settings) }

  describe "#up" do
    it 'updates setting' do
      settings.create!(package_metadata_purl_types: [1, 2, 4, 5, 9, 10])

      disable_migrations_output do
        migrate!
      end

      expect(ApplicationSetting.last.package_metadata_purl_types).to eq([1, 2, 4, 5, 9, 10, 14])
    end
  end

  describe "#down" do
    context 'with default value' do
      it 'updates setting' do
        settings.create!(package_metadata_purl_types: [1, 2, 4, 5, 9, 10, 14])

        disable_migrations_output do
          migrate!
          schema_migrate_down!
        end

        expect(ApplicationSetting.last.package_metadata_purl_types).to eq([1, 2, 4, 5, 9, 10])
      end
    end
  end
end
