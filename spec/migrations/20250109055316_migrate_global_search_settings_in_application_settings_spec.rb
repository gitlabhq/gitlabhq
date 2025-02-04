# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateGlobalSearchSettingsInApplicationSettings, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#down' do
    let(:migration) { described_class.new }

    context 'when search settings is already set' do
      it 'does not update the search settings' do
        migration.up
        expect { migration.down }.to change { application_setting.reload.search }.to({})
      end
    end
  end

  describe '#up' do
    context 'when search is not already set' do
      before do
        stub_feature_flags(global_search_code_tab: false)
        stub_feature_flags(global_search_commits_tab: false)
        stub_feature_flags(global_search_issues_tab: false)
      end

      it 'migrates search from the feature flags in the application_settings successfully' do
        expected_search = if ::Gitlab.ee?
                            {
                              'global_search_code_enabled' => false,
                              'global_search_commits_enabled' => false,
                              'global_search_epics_enabled' => true,
                              'global_search_issues_enabled' => false,
                              'global_search_merge_requests_enabled' => true,
                              'global_search_snippet_titles_enabled' => true,
                              'global_search_users_enabled' => true,
                              'global_search_wiki_enabled' => true
                            }
                          else
                            {
                              'global_search_issues_enabled' => false,
                              'global_search_merge_requests_enabled' => true,
                              'global_search_snippet_titles_enabled' => true,
                              'global_search_users_enabled' => true
                            }
                          end

        expect { migrate! }.to change {
          application_setting.reload.search
        }.from({}).to(expected_search)
      end
    end
  end
end
