# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdatePackageMetadataSyncSetting, feature_category: :software_composition_analysis do
  let(:settings) { table(:application_settings) }
  let(:fully_enabled_sync_setting) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] }

  describe "#up" do
    context 'with default value' do
      let(:fully_disabled_sync) { [] }

      it 'updates setting' do
        settings.create!(package_metadata_purl_types: fully_disabled_sync)

        migrate!

        expect(ApplicationSetting.last.package_metadata_purl_types).to eq(fully_enabled_sync_setting)
      end
    end

    context 'with custom value' do
      let(:partially_enabled_sync) { [1, 2, 3, 4, 5] }

      it 'does not change setting' do
        settings.create!(package_metadata_purl_types: partially_enabled_sync)

        migrate!

        expect(ApplicationSetting.last.package_metadata_purl_types).to eq(partially_enabled_sync)
      end
    end
  end
end
