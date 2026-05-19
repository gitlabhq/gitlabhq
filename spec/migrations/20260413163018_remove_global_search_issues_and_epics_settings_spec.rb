# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveGlobalSearchIssuesAndEpicsSettings, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#up' do
    let(:migration) { described_class.new }

    context 'when global_search_issues_enabled and global_search_epics_enabled exist' do
      before do
        search_settings = application_setting.search || {}
        search_settings['global_search_issues_enabled'] = true
        search_settings['global_search_epics_enabled'] = false
        search_settings['global_search_work_items_enabled'] = true
        application_setting.update_columns(search: search_settings)
      end

      it 'removes both deprecated settings' do
        expected_search = application_setting.reload.search.except(
          'global_search_issues_enabled',
          'global_search_epics_enabled'
        )

        expect { migration.up }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end

      it 'keeps other search settings intact' do
        migration.up

        expect(application_setting.reload.search['global_search_work_items_enabled']).to be(true)
      end
    end

    context 'when settings do not exist' do
      before do
        search_settings = application_setting.search || {}
        search_settings['global_search_work_items_enabled'] = true
        application_setting.update_columns(search: search_settings)
      end

      it 'does not fail and keeps existing settings' do
        expect { migration.up }.not_to raise_error
        expect(application_setting.reload.search['global_search_work_items_enabled']).to be(true)
      end
    end

    context 'when search column is empty hash' do
      before do
        application_setting.update_columns(search: {})
      end

      it 'does not raise an error' do
        expect { migration.up }.not_to raise_error
      end

      it 'keeps search as empty hash' do
        migration.up
        expect(application_setting.reload.search).to eq({})
      end
    end
  end

  describe '#down' do
    let(:migration) { described_class.new }

    before do
      search_settings = application_setting.search || {}
      search_settings['global_search_work_items_enabled'] = true
      application_setting.update_columns(search: search_settings)
    end

    it 'is a no-op (migration is irreversible)' do
      expect { migration.down }.not_to change { application_setting.reload.search }
    end
  end
end
