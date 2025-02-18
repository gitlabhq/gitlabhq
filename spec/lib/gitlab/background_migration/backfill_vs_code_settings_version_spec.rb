# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillVsCodeSettingsVersion, schema: 20231220225325, feature_category: :web_ide do
  let(:vs_code_settings) { table(:vs_code_settings) }

  let(:users) { table(:users) }

  let(:user) do
    users.create!(
      email: "test1@example.com",
      username: "test1",
      notification_email: "test@example.com",
      name: "test",
      state: "active",
      projects_limit: 10)
  end

  let(:persistent_settings) { VsCode::Settings::SETTINGS_TYPES.filter { |type| type != 'machines' } }

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
    context 'when it finds vs_code_setting rows with version that is nil or zero' do
      let(:settings) do
        persistent_settings.each_with_index.map do |type, index|
          vs_code_settings.create!(user_id: user.id,
            setting_type: type,
            content: '{}',
            uuid: SecureRandom.uuid,
            version: index.odd? ? nil : 0)
        end
      end

      it 'sets version field with default value for setting type' do
        settings.each do |setting|
          expect(setting.version).to eq(nil).or eq(0)
        end

        migration.perform

        settings.each do |setting|
          expect(setting.reload.version)
            .to eq(described_class::VsCodeSetting::DEFAULT_SETTING_VERSIONS[setting.setting_type])
        end
      end
    end

    context 'when it finds vs_code_setting rows with version that is not nil or zero' do
      let(:settings) do
        persistent_settings.map do |type|
          vs_code_settings.create!(user_id: user.id,
            setting_type: type,
            content: '{}',
            uuid: SecureRandom.uuid,
            version: 1)
        end
      end

      it 'does not set version field' do
        settings.each do |setting|
          expect(setting.version).to eq(1)
        end

        migration.perform

        settings.each do |setting|
          expect(setting.reload.version).to eq(1)
        end
      end
    end
  end
end
