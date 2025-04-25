# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillVsCodeSettingsSettingsContextHash, feature_category: :web_ide do
  let(:vs_code_settings) { table(:vs_code_settings) }

  let(:users) { table(:users) }

  let!(:user) do
    users.create!(
      email: "test1@example.com",
      username: "test1",
      notification_email: "test@example.com",
      name: "test",
      state: "active",
      projects_limit: 10)
  end

  subject(:migration) do
    described_class.new(
      start_id: vs_code_settings.first.id,
      end_id: vs_code_settings.last.id,
      batch_table: :vs_code_settings,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  describe "#perform" do
    context 'for vs_code_settings records with empty settings context hash' do
      let(:non_extensions_vs_code_setting) do
        vs_code_settings.create!(
          user_id: user.id,
          uuid: SecureRandom.uuid,
          settings_context_hash: nil,
          setting_type: 'profiles',
          content: '{}'
        )
      end

      it 'does not update settings context hash if setting type is not extensions' do
        expect(non_extensions_vs_code_setting.settings_context_hash).to be_nil

        migration.perform

        expect(non_extensions_vs_code_setting.reload.settings_context_hash).to be_nil
      end
    end
  end
end
