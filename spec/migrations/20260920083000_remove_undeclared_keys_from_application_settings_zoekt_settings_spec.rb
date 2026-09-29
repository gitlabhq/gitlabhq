# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveUndeclaredKeysFromApplicationSettingsZoektSettings,
  migration: :gitlab_main, feature_category: :global_search do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when zoekt_settings carries a key the schema does not declare' do
      let!(:app_setting) do
        application_settings.create!(
          zoekt_settings: { 'zoekt_indexing_enabled' => true, 'zoekt_orphaned_key' => 2 }
        )
      end

      it 'removes only the undeclared key' do
        migrate!

        expect(app_setting.reload.zoekt_settings).to eq({ 'zoekt_indexing_enabled' => true })
      end
    end

    context 'when zoekt_settings carries only declared keys' do
      let!(:app_setting) do
        application_settings.create!(zoekt_settings: { 'zoekt_max_restarts_15m' => 2 })
      end

      it 'leaves the row untouched' do
        migrate!

        expect(app_setting.reload.zoekt_settings).to eq({ 'zoekt_max_restarts_15m' => 2 })
      end
    end

    context 'when zoekt_settings is empty' do
      let!(:app_setting) { application_settings.create!(zoekt_settings: {}) }

      it 'leaves the row untouched' do
        migrate!

        expect(app_setting.reload.zoekt_settings).to eq({})
      end
    end

    context 'when a settings row the model can load carries an undeclared key' do
      let!(:setting) { ApplicationSetting.create_from_defaults }

      before do
        application_settings.where(id: setting.id).update_all(
          %q(zoekt_settings = zoekt_settings || '{"zoekt_orphaned_key": 2}'::jsonb)
        )
      end

      # zoekt_settings validation is EE-only, so the pre-migration save only fails under EE.
      # The bug this migration exists for: additionalProperties is false, so a single undeclared key
      # makes every settings save fail, including saves of attributes unrelated to search.
      it 'unblocks saving an unrelated attribute', if: Gitlab.ee? do
        expect(ApplicationSetting.find(setting.id).update(gravatar_enabled: true)).to be(false)

        migrate!

        expect(ApplicationSetting.find(setting.id).update(gravatar_enabled: true)).to be(true)
      end
    end

    context 'when zoekt_settings holds a non-object jsonb' do
      let!(:app_setting) { application_settings.create!(zoekt_settings: {}) }
      let!(:other) do
        application_settings.create!(
          zoekt_settings: { 'zoekt_indexing_enabled' => true, 'zoekt_orphaned_key' => 2 }
        )
      end

      before do
        application_settings.where(id: app_setting.id).update_all("zoekt_settings = '[]'::jsonb")
      end

      it 'skips the broken row and still cleans the others' do
        expect { migrate! }.not_to raise_error

        expect(app_setting.reload.zoekt_settings).to eq([])
        expect(other.reload.zoekt_settings).to eq({ 'zoekt_indexing_enabled' => true })
      end
    end
  end
end
