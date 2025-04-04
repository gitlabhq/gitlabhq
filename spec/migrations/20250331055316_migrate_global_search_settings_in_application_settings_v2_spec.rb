# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateGlobalSearchSettingsInApplicationSettingsV2, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#down' do
    let(:migration) { described_class.new }

    context 'when search settings is already set' do
      it 'removes the global search settings' do
        migration.up
        expected_search = application_setting.reload.search
        expected_search.delete('global_search_block_anonymous_searches_enabled')
        expected_search.delete('global_search_limited_indexing_enabled')
        expect { migration.down }.to change { application_setting.reload.search }.to(expected_search)
      end
    end
  end

  describe '#up' do
    context 'when both ff are enabled' do
      it 'migrates search from the feature flags in the application_settings successfully' do
        search_settings = application_setting.reload.search
        expected_settings = if ::Gitlab.ee?
                              {
                                'global_search_limited_indexing_enabled' => true,
                                'global_search_block_anonymous_searches_enabled' => true
                              }
                            else
                              {
                                'global_search_block_anonymous_searches_enabled' => true
                              }
                            end

        expected_search = search_settings.merge(expected_settings)
        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end

    context 'when both ff are disabled' do
      before do
        stub_feature_flags(block_anonymous_global_searches: false)
        stub_feature_flags(advanced_global_search_for_limited_indexing: false)
      end

      it 'migrates search from the feature flags in the application_settings successfully' do
        search_settings = application_setting.reload.search
        expected_settings = if ::Gitlab.ee?
                              {
                                'global_search_limited_indexing_enabled' => false,
                                'global_search_block_anonymous_searches_enabled' => false
                              }
                            else
                              {
                                'global_search_block_anonymous_searches_enabled' => false
                              }
                            end

        expected_search = search_settings.merge(expected_settings)
        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end
  end
end
