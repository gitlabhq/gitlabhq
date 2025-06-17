# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateAnonymousSearchesFlagToApplicationSettingsV2, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#down' do
    let(:migration) { described_class.new }

    context 'when search settings is already set' do
      it 'removes the global search settings' do
        migration.up
        expected_search = application_setting.reload.search
        expected_search.delete('anonymous_searches_allowed')
        expect { migration.down }.to change { application_setting.reload.search }.to(expected_search)
      end
    end
  end

  describe '#up' do
    context 'when ff is enabled' do
      it 'migrates search from the feature flags in the application_settings successfully' do
        search_settings = application_setting.reload.search
        expected_settings = { 'anonymous_searches_allowed' => true }

        expected_search = search_settings.merge(expected_settings)
        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end

    context 'when both ff are disabled' do
      before do
        stub_feature_flags(allow_anonymous_searches: false)
      end

      it 'migrates search from the feature flags in the application_settings successfully' do
        search_settings = application_setting.reload.search
        expected_settings = {
          'anonymous_searches_allowed' => false
        }

        expected_search = search_settings.merge(expected_settings)
        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end
  end
end
