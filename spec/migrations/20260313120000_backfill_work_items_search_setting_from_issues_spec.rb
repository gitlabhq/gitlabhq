# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillWorkItemsSearchSettingFromIssues, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#down' do
    let(:migration) { described_class.new }

    context 'when search settings is already set' do
      it 'removes the global_search_work_items_enabled setting' do
        migration.up
        expected_search = application_setting.reload.search
        expected_search.delete('global_search_work_items_enabled')
        expect { migration.down }.to change { application_setting.reload.search }.to(expected_search)
      end
    end
  end

  describe '#up' do
    context 'when global_search_issues_enabled is true' do
      before do
        search_settings = application_setting.search
        search_settings['global_search_issues_enabled'] = true
        application_setting.update_columns(search: search_settings)
      end

      it 'copies the value to global_search_work_items_enabled' do
        search_settings = application_setting.reload.search
        expected_search = search_settings.merge('global_search_work_items_enabled' => true)

        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end

    context 'when global_search_issues_enabled is false' do
      before do
        search_settings = application_setting.search
        search_settings['global_search_issues_enabled'] = false
        application_setting.update_columns(search: search_settings)
      end

      it 'copies the false value to global_search_work_items_enabled' do
        search_settings = application_setting.reload.search
        expected_search = search_settings.merge('global_search_work_items_enabled' => false)

        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end

    context 'when global_search_issues_enabled does not exist' do
      it 'defaults global_search_work_items_enabled to true' do
        search_settings = application_setting.reload.search
        expected_search = search_settings.merge('global_search_work_items_enabled' => true)

        expect { migrate! }.to change {
          application_setting.reload.search
        }.to eq(expected_search)
      end
    end
  end
end
